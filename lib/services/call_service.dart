import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/api_constants.dart';
import '../core/utils/storage_service.dart';

enum CallType {
  voice,
  video,
}

enum CallState {
  idle,
  calling,
  ringing,
  connected,
  ended,
  rejected,
  busy,
}

class CallService {
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  CallState _callState = CallState.idle;
  CallType? _currentCallType;
  String? _currentCallId;
  String? _currentConversationId;
  String? _otherUserId;
  bool _isRecording = false;
  bool _isSpeakerEnabled = false;
  
  IO.Socket? _socket;
  final StorageService _storage = StorageService();
  
  // Callbacks
  Function(CallState)? onCallStateChanged;
  Function(webrtc.MediaStream?)? onLocalStream;
  Function(webrtc.MediaStream?)? onRemoteStream;
  Function(String)? onCallError;
  Function(Map<String, dynamic>)? onIncomingCall;
  
  CallService() {
    _initializeSocket();
  }
  
  CallState get callState => _callState;
  CallType? get callType => _currentCallType;
  String? get callId => _currentCallId;
  String? get conversationId => _currentConversationId;
  webrtc.MediaStream? get localStream => _localStream;
  webrtc.MediaStream? get remoteStream => _remoteStream;
  
  Future<void> _initializeSocket() async {
    final token = await _storage.getToken();
    if (token == null) {
      print('CallService: No token available for socket connection');
      return;
    }
    
    try {
      _socket = IO.io(
        ApiConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );
      
      _socket!.on('connect', (_) {
        print('CallService: Socket connected');
      });
      
      _socket!.on('disconnect', (_) {
        print('CallService: Socket disconnected');
      });
      
      _socket!.on('connect_error', (error) {
        print('CallService: Connection error: $error');
      });
      
      _setupSocketListeners();
      
      // Connect if not already connected
      if (!_socket!.connected) {
        _socket!.connect();
      }
    } catch (e) {
      print('CallService: Error initializing socket: $e');
    }
  }
  
  void _setupSocketListeners() {
    if (_socket == null) return;
    
    // Incoming call
    _socket!.on('incomingCall', (data) {
      _handleIncomingCall(data);
    });
    
    // Call accepted
    _socket!.on('callAccepted', (data) {
      _handleCallAccepted(data);
    });
    
    // Call rejected
    _socket!.on('callRejected', (data) {
      _handleCallRejected(data);
    });
    
    // Call ended
    _socket!.on('callEnded', (data) {
      _handleCallEnded(data);
    });
    
    // ICE candidate
    _socket!.on('iceCandidate', (data) {
      _handleIceCandidate(data);
    });
    
    // Offer/Answer
    _socket!.on('offer', (data) {
      _handleOffer(data);
    });
    
    _socket!.on('answer', (data) {
      _handleAnswer(data);
    });

    // Handle video upgrade
    _socket!.on('upgradeToVideo', (data) {
      _handleVideoUpgrade(data);
    });

    // Handle recording notifications
    _socket!.on('recordingStarted', (data) {
      print('Recording started by other party');
    });

    _socket!.on('recordingStopped', (data) {
      print('Recording stopped by other party');
    });
  }
  
  Future<bool> _requestPermissions(CallType callType) async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        print('Microphone permission denied: $micStatus');
        return false;
      }

      // Request camera permission if it's a video call
      if (callType == CallType.video) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          print('Camera permission denied: $cameraStatus');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }
  
  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };
    
    _peerConnection = await webrtc.createPeerConnection(configuration);
    
    _peerConnection!.onIceCandidate = (webrtc.RTCIceCandidate candidate) {
      _socket?.emit('iceCandidate', {
        'callId': _currentCallId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpMid': candidate.sdpMid,
        },
      });
    };
    
    _peerConnection!.onAddStream = (webrtc.MediaStream stream) {
      print('CallService: Remote stream added via onAddStream');
      _remoteStream = stream;
      onRemoteStream?.call(stream);
    };
    
    _peerConnection!.onTrack = (webrtc.RTCTrackEvent event) {
      print('CallService: Remote track received via onTrack');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream);
      } else if (event.track != null && _remoteStream == null) {
        // If we don't have a stream yet, try to get it from the peer connection
        // The stream should be available through the peer connection's receivers
        print('CallService: Track received but no stream, waiting for stream...');
      }
    };
    
    _peerConnection!.onConnectionState = (webrtc.RTCPeerConnectionState state) {
      print('CallService: Peer connection state: $state');
      if (state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        print('CallService: Connection failed or disconnected');
      }
    };
  }
  
  Future<void> startCall(String conversationId, String otherUserId, CallType callType) async {
    try {
      if (_callState != CallState.idle) {
        throw Exception('Call already in progress');
      }
      
      final hasPermissions = await _requestPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Camera/Microphone permissions denied');
      }
      
      _currentCallType = callType;
      _currentConversationId = conversationId;
      _otherUserId = otherUserId;
      _currentCallId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get local media stream first
      final constraints = {
        'audio': true,
        'video': callType == CallType.video ? {
          'facingMode': 'user',
        } : false,
      };
      
      _localStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      onLocalStream?.call(_localStream);
      
      // Create peer connection after getting media
      await _createPeerConnection();
      
      // Add local stream tracks to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      
      // Wait a bit for tracks to be added
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Create offer with proper constraints
      final offerConstraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': callType == CallType.video,
      };
      
      final offer = await _peerConnection!.createOffer(offerConstraints);
      
      // Set local description before sending
      await _peerConnection!.setLocalDescription(offer);
      
      // Wait for local description to be set
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Send call request
      _socket?.emit('startCall', {
        'callId': _currentCallId,
        'conversationId': conversationId,
        'otherUserId': otherUserId,
        'callType': callType == CallType.video ? 'video' : 'voice',
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });
      
      _callState = CallState.calling;
      onCallStateChanged?.call(_callState);
    } catch (e) {
      print('Error starting call: $e');
      _callState = CallState.idle;
      onCallError?.call(e.toString());
      await _cleanup();
      rethrow;
    }
  }
  
  Future<void> acceptCall(Map<String, dynamic> callData) async {
    try {
      _currentCallId = callData['callId'];
      _currentConversationId = callData['conversationId'];
      _otherUserId = callData['callerId'];
      _currentCallType = callData['callType'] == 'video' ? CallType.video : CallType.voice;
      
      final hasPermissions = await _requestPermissions(_currentCallType!);
      if (!hasPermissions) {
        rejectCall();
        throw Exception('Camera/Microphone permissions denied');
      }
      
      // Get local media stream first
      final constraints = {
        'audio': true,
        'video': _currentCallType == CallType.video ? {
          'facingMode': 'user',
        } : false,
      };
      
      _localStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      onLocalStream?.call(_localStream);
      
      // Create peer connection after getting media
      await _createPeerConnection();
      
      // Add local stream tracks to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      
      // Wait a bit for tracks to be added
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Set remote description from offer first
      final offer = webrtc.RTCSessionDescription(
        callData['offer']['sdp'],
        callData['offer']['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
      
      // Wait for remote description to be set
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Create answer with proper constraints
      final answerConstraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': _currentCallType == CallType.video,
      };
      
      final answer = await _peerConnection!.createAnswer(answerConstraints);
      await _peerConnection!.setLocalDescription(answer);
      
      // Wait for local description to be set
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Send answer
      _socket?.emit('acceptCall', {
        'callId': _currentCallId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      
      _callState = CallState.connected;
      onCallStateChanged?.call(_callState);
    } catch (e) {
      print('Error accepting call: $e');
      _callState = CallState.idle;
      onCallError?.call(e.toString());
      await _cleanup();
      rethrow;
    }
  }
  
  Future<void> rejectCall() async {
    _socket?.emit('rejectCall', {
      'callId': _currentCallId,
    });
    
    _callState = CallState.rejected;
    onCallStateChanged?.call(_callState);
    await _cleanup();
  }
  
  Future<void> endCall() async {
    _socket?.emit('endCall', {
      'callId': _currentCallId,
    });
    
    _callState = CallState.ended;
    onCallStateChanged?.call(_callState);
    await _cleanup();
  }
  
  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        audioTracks[0].enabled = !audioTracks[0].enabled!;
      }
    }
  }
  
  Future<void> toggleVideo() async {
    if (_localStream != null && _currentCallType == CallType.video) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        videoTracks[0].enabled = !videoTracks[0].enabled!;
      }
    }
  }
  
  Future<void> switchCamera() async {
    if (_localStream != null && _currentCallType == CallType.video) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await webrtc.Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  Future<void> switchToVideo() async {
    if (_callState != CallState.connected || _currentCallType == CallType.video) {
      return;
    }

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        throw Exception('Camera permission denied');
      }

      // Add video track to existing stream
      final constraints = {
        'video': {
          'facingMode': 'user',
        },
      };
      
      final videoStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      final videoTracks = videoStream.getVideoTracks();
      
      if (videoTracks.isNotEmpty && _localStream != null && _peerConnection != null) {
        // Add video track to local stream
        _localStream!.addTrack(videoTracks[0]);
        
        // Add track to peer connection
        _peerConnection!.addTrack(videoTracks[0], _localStream!);
        
        // Create new offer with video
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        
        // Notify other party about video upgrade
        _socket?.emit('upgradeToVideo', {
          'callId': _currentCallId,
          'offer': {
            'type': offer.type,
            'sdp': offer.sdp,
          },
        });
        
        _currentCallType = CallType.video;
        onLocalStream?.call(_localStream);
      }
    } catch (e) {
      print('Error switching to video: $e');
      rethrow;
    }
  }

  Future<void> toggleSpeaker() async {
    // Note: Speaker toggle is typically handled by the system audio routing
    // This is a placeholder - actual implementation depends on platform-specific audio routing
    _isSpeakerEnabled = !_isSpeakerEnabled;
    // In a real implementation, you would use platform channels or audio routing APIs
    print('Speaker toggled: $_isSpeakerEnabled');
  }

  bool get isSpeakerEnabled => _isSpeakerEnabled;

  Future<void> startRecording() async {
    if (_isRecording || _callState != CallState.connected) {
      return;
    }

    try {
      // Request storage permission for saving recording
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        await Permission.storage.request();
      }

      _isRecording = true;
      // Note: Actual recording implementation would require MediaRecorder API
      // This is a placeholder - you would need to implement actual recording
      print('Call recording started');
      
      // Notify backend about recording start
      _socket?.emit('startRecording', {
        'callId': _currentCallId,
      });
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      _isRecording = false;
      print('Call recording stopped');
      
      // Notify backend about recording stop
      _socket?.emit('stopRecording', {
        'callId': _currentCallId,
      });
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  bool get isRecording => _isRecording;
  
  void _handleIncomingCall(Map<String, dynamic> data) {
    onIncomingCall?.call(data);
  }
  
  void _handleCallAccepted(Map<String, dynamic> data) {
    if (data['callId'] == _currentCallId) {
      _callState = CallState.connected;
      onCallStateChanged?.call(_callState);
      
      // Set remote description from answer if provided
      if (data['answer'] != null && _peerConnection != null) {
        final answer = webrtc.RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        _peerConnection!.setRemoteDescription(answer).catchError((e) {
          print('Error setting remote description from answer: $e');
        });
      }
    }
  }
  
  void _handleCallRejected(Map<String, dynamic> data) {
    if (data['callId'] == _currentCallId) {
      _callState = CallState.rejected;
      onCallStateChanged?.call(_callState);
      _cleanup();
    }
  }
  
  void _handleCallEnded(Map<String, dynamic> data) {
    if (data['callId'] == _currentCallId) {
      _callState = CallState.ended;
      onCallStateChanged?.call(_callState);
      _cleanup();
    }
  }
  
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    if (data['callId'] == _currentCallId && _peerConnection != null) {
      final candidate = webrtc.RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    }
  }
  
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (data['callId'] == _currentCallId && _peerConnection != null) {
      final offer = webrtc.RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
      
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      
      _socket?.emit('answer', {
        'callId': _currentCallId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
    }
  }
  
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (data['callId'] == _currentCallId && _peerConnection != null) {
      final answer = webrtc.RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
    }
  }

  Future<void> _handleVideoUpgrade(Map<String, dynamic> data) async {
    if (data['callId'] == _currentCallId && _peerConnection != null) {
      try {
        // Request camera permission if not already granted
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isDenied) {
          final result = await Permission.camera.request();
          if (!result.isGranted) {
            print('Camera permission denied for video upgrade');
            return;
          }
        }

        // Add video track to local stream
        final constraints = {
          'video': {
            'facingMode': 'user',
          },
        };
        
        final videoStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
        final videoTracks = videoStream.getVideoTracks();
        
        if (videoTracks.isNotEmpty && _localStream != null) {
          _localStream!.addTrack(videoTracks[0]);
          _peerConnection!.addTrack(videoTracks[0], _localStream!);
          onLocalStream?.call(_localStream);
        }

        // Set remote description from offer
        final offer = webrtc.RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );
        await _peerConnection!.setRemoteDescription(offer);

        // Create answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        // Send answer
        _socket?.emit('answer', {
          'callId': _currentCallId,
          'answer': {
            'type': answer.type,
            'sdp': answer.sdp,
          },
        });

        _currentCallType = CallType.video;
      } catch (e) {
        print('Error handling video upgrade: $e');
      }
    }
  }
  
  Future<void> _cleanup() async {
    try {
      // Stop all tracks before disposing streams
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });
      
      await _localStream?.dispose();
      await _remoteStream?.dispose();
      
      // Close peer connection
      if (_peerConnection != null) {
        try {
          await _peerConnection!.close();
        } catch (e) {
          print('Error closing peer connection: $e');
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    } finally {
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      _currentCallId = null;
      _currentConversationId = null;
      _otherUserId = null;
      _currentCallType = null;
      
      if (_callState != CallState.ended && _callState != CallState.rejected) {
        _callState = CallState.idle;
        onCallStateChanged?.call(_callState);
      }
    }
  }
  
  void dispose() {
    _cleanup();
  }
}

