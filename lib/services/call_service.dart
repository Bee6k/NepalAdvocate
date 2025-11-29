import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/api_constants.dart';
import '../core/utils/storage_service.dart';
import '../models/message_model.dart';

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
  DateTime? _callStartTime;
  DateTime? _callConnectedTime;
  
  IO.Socket? _socket;
  final StorageService _storage = StorageService();
  
  // Chat service for sending call status messages
  Function(String conversationId, String content, MessageType messageType)? _sendChatMessage;
  void setChatMessageHandler(Function(String, String, MessageType) handler) {
    _sendChatMessage = handler;
  }
  
  // Callbacks
  Function(CallState)? onCallStateChanged;
  Function(webrtc.MediaStream?)? onLocalStream;
  Function(webrtc.MediaStream?)? onRemoteStream;
  Function(String)? onCallError;
  Function(Map<String, dynamic>)? onIncomingCall;
  Function()? onConnect;
  Function()? onDisconnect;
  
  // Store incoming call data for retrieval
  Map<String, dynamic>? _storedIncomingCallData;
  Map<String, dynamic>? get storedIncomingCallData => _storedIncomingCallData;
  
  CallService() {
    _initializeSocket();
  }
  
  bool get isConnected => _socket?.connected ?? false;
  
  Future<void> connect() async {
    if (_socket?.connected ?? false) {
      print('CallService: Already connected');
      return;
    }
    await _initializeSocket();
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
        // Re-setup listeners after connection to ensure they're active
        _setupSocketListeners();
        // Trigger connect callback
        onConnect?.call();
      });
      
      _socket!.on('disconnect', (_) {
        print('CallService: Socket disconnected');
        onDisconnect?.call();
      });
      
      _socket!.on('connect_error', (error) {
        print('CallService: Connection error: $error');
      });
      
      _setupSocketListeners();
      
      // Connect if not already connected
      if (!_socket!.connected) {
        _socket!.connect();
      } else {
        // If already connected, ensure listeners are set up
        _setupSocketListeners();
      }
    } catch (e) {
      print('CallService: Error initializing socket: $e');
    }
  }
  
  void _setupSocketListeners() {
    if (_socket == null) return;
    
    // Remove existing listeners to avoid duplicates
    _socket!.off('incomingCall');
    _socket!.off('callAccepted');
    _socket!.off('callRejected');
    _socket!.off('callEnded');
    _socket!.off('iceCandidate');
    _socket!.off('offer');
    _socket!.off('answer');
    _socket!.off('upgradeToVideo');
    _socket!.off('recordingStarted');
    _socket!.off('recordingStopped');
    
    // Incoming call - ensure this listener is always active
    _socket!.on('incomingCall', (data) {
      print('CallService: ⚡ Socket received incomingCall event!');
      print('CallService: Incoming call data: $data');
      print('CallService: Call ID: ${data['callId']}, Caller ID: ${data['callerId']}');
      print('CallService: Has offer: ${data['offer'] != null}');
      _handleIncomingCall(data);
    });
    
    print('CallService: ✅ Incoming call listener registered and active');
    
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
      print('CallService: Starting new call - conversationId: $conversationId, otherUserId: $otherUserId, type: $callType');
      print('CallService: Current call state: $_callState, currentCallId: $_currentCallId');
      
      // If there's an existing call for the same conversation/user, clear it first
      if (_callState != CallState.idle) {
        final isSameConversation = _currentConversationId == conversationId;
        final isSameUser = _otherUserId == otherUserId;
        
        if (isSameConversation || isSameUser) {
          print('CallService: Clearing previous call for same conversation/user before starting new call');
          await _cleanup();
        } else {
          print('CallService: Cannot start call - state is $_callState, expected idle');
          throw Exception('Call already in progress. Current state: $_callState');
        }
      }
      
      // Check socket connection
      if (_socket == null || !_socket!.connected) {
        print('CallService: Socket not connected - socket: ${_socket != null}, connected: ${_socket?.connected}');
        throw Exception('Socket not connected. Please check your internet connection.');
      }
      
      print('CallService: Socket is connected, proceeding with call setup');
      
      final hasPermissions = await _requestPermissions(callType);
      if (!hasPermissions) {
        throw Exception('Camera/Microphone permissions denied');
      }
      
      _currentCallType = callType;
      _currentConversationId = conversationId;
      _otherUserId = otherUserId;
      _currentCallId = DateTime.now().millisecondsSinceEpoch.toString();
      _callStartTime = DateTime.now(); // Track call start time
      _callConnectedTime = null; // Reset connected time
      
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
      
      if (_peerConnection == null) {
        throw Exception('Failed to create peer connection');
      }
      
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
      if (_currentCallId == null) {
        throw Exception('Call ID generation failed');
      }
      
      _socket!.emit('startCall', {
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
      onCallStateChanged?.call(_callState);
      onCallError?.call(e.toString());
      await _cleanup();
      rethrow;
    }
  }
  
  Future<void> acceptCall(Map<String, dynamic> callData) async {
    try {
      // Validate required data
      if (callData['callId'] == null) {
        throw Exception('Call ID is required');
      }
      if (callData['offer'] == null || callData['offer']['sdp'] == null || callData['offer']['type'] == null) {
        throw Exception('Call offer is required');
      }
      
      _currentCallId = callData['callId']?.toString();
      _currentConversationId = callData['conversationId']?.toString();
      _otherUserId = callData['callerId']?.toString();
      _currentCallType = callData['callType'] == 'video' ? CallType.video : CallType.voice;
      
      if (_currentCallType == null) {
        throw Exception('Call type is required');
      }
      
      // Check socket connection
      if (_socket == null || !_socket!.connected) {
        throw Exception('Socket not connected');
      }
      
      final hasPermissions = await _requestPermissions(_currentCallType!);
      if (!hasPermissions) {
        await rejectCall();
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
      
      if (_peerConnection == null) {
        throw Exception('Failed to create peer connection');
      }
      
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
      if (_currentCallId == null) {
        throw Exception('Call ID is missing');
      }
      
      _socket!.emit('acceptCall', {
        'callId': _currentCallId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      
      _callState = CallState.connected;
      _callConnectedTime = DateTime.now(); // Track when call was connected
      onCallStateChanged?.call(_callState);
    } catch (e) {
      print('Error accepting call: $e');
      _callState = CallState.idle;
      onCallStateChanged?.call(_callState);
      onCallError?.call(e.toString());
      await _cleanup();
      rethrow;
    }
  }
  
  Future<void> rejectCall() async {
    print('CallService: Rejecting call...');
    final callId = _currentCallId;
    final conversationId = _currentConversationId;
    final callType = _currentCallType;
    
    // Send call rejected message to chat
    if (conversationId != null && _sendChatMessage != null) {
      final callTypeText = callType == CallType.video ? 'Video' : 'Voice';
      _sendChatMessage!(
        conversationId,
        'Call rejected',
        MessageType.system,
      );
    }
    
    // Emit reject event if we have a call ID and socket is connected
    if (callId != null && _socket != null && _socket!.connected) {
      print('CallService: Emitting rejectCall event with callId: $callId');
      _socket!.emit('rejectCall', {
        'callId': callId,
      });
    } else {
      print('CallService: No call ID or socket not connected, skipping emit');
    }
    
    // Force immediate cleanup
    _forceCleanup();
    print('CallService: Call rejected and cleaned up, ready for new call');
  }
  
  Future<void> endCall() async {
    print('CallService: Ending call...');
    final callId = _currentCallId;
    final conversationId = _currentConversationId;
    final callType = _currentCallType;
    
    // Calculate call duration
    String durationText = '';
    if (_callConnectedTime != null && _callStartTime != null) {
      final duration = DateTime.now().difference(_callConnectedTime!);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      if (minutes > 0) {
        durationText = '${minutes}m ${seconds}s';
      } else {
        durationText = '${seconds}s';
      }
    }
    
    // Send call ended message to chat with duration
    if (conversationId != null && _sendChatMessage != null) {
      final callTypeText = callType == CallType.video ? 'Video' : 'Voice';
      final message = durationText.isNotEmpty 
          ? '$callTypeText call ended - Duration: $durationText'
          : '$callTypeText call ended';
      _sendChatMessage!(
        conversationId,
        message,
        MessageType.system,
      );
    }
    
    // Emit end event if we have a call ID and socket is connected
    if (callId != null && _socket != null && _socket!.connected) {
      print('CallService: Emitting endCall event with callId: $callId');
      _socket!.emit('endCall', {
        'callId': callId,
      });
    } else {
      print('CallService: No call ID or socket not connected, skipping emit');
    }
    
    // Force immediate cleanup before setting state
    _forceCleanup();
    print('CallService: Call ended and cleaned up, ready for new call');
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
      if (_socket != null && _socket!.connected && _currentCallId != null) {
        _socket!.emit('startRecording', {
          'callId': _currentCallId,
        });
      }
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
      if (_socket != null && _socket!.connected && _currentCallId != null) {
        _socket!.emit('stopRecording', {
          'callId': _currentCallId,
        });
      }
    } catch (e) {
      print('Error stopping recording: $e');
      rethrow;
    }
  }

  bool get isRecording => _isRecording;
  
  void _handleIncomingCall(Map<String, dynamic> data) {
    try {
      print('CallService: Incoming call received: $data');
      print('CallService: Current call state: $_callState, currentCallId: $_currentCallId');
      
      // Validate required data
      if (data['callId'] == null) {
        print('CallService: Error - Call ID is missing in incoming call data');
        return;
      }
      if (data['offer'] == null) {
        print('CallService: Error - Call offer is missing in incoming call data');
        return;
      }
      
      final incomingCallId = data['callId']?.toString();
      final incomingConversationId = data['conversationId']?.toString();
      final incomingCallerId = data['callerId']?.toString();
      
      // If we're in a non-idle state with the same call ID, ignore (duplicate event)
      if (_callState != CallState.idle && _currentCallId == incomingCallId) {
        print('CallService: Duplicate incoming call event for same call ID - ignoring');
        return;
      }
      
      // If we have an active call but it's for the same conversation/user, clear it and accept new call
      if (_callState != CallState.idle && _currentCallId != incomingCallId) {
        final isSameConversation = _currentConversationId == incomingConversationId;
        final isSameUser = _otherUserId == incomingCallerId;
        
        if (isSameConversation || isSameUser) {
          print('CallService: Previous call was for same conversation/user, clearing it and accepting new call');
          // Force immediate cleanup for same conversation/user
          _forceCleanup();
          // Process the new call
          _processIncomingCall(data);
          return;
        } else {
          // Different conversation/user - reject the new call
          print('CallService: Already have an active call ($_currentCallId) for different conversation/user, rejecting new call ($incomingCallId)');
          if (_socket != null && _socket!.connected) {
            _socket!.emit('rejectCall', {
              'callId': incomingCallId,
            });
          }
          return;
        }
      }
      
      // If we're in ended/rejected state, always allow new calls (cleanup should have happened)
      if (_callState == CallState.ended || _callState == CallState.rejected) {
        print('CallService: Previous call was ended/rejected, forcing cleanup and accepting new call');
        _forceCleanup();
        _processIncomingCall(data);
        return;
      }
      
      // If we're in idle state, process normally
      if (_callState == CallState.idle) {
        _processIncomingCall(data);
      } else {
        // For any other state, cleanup first then process
        print('CallService: Cleaning up previous call state before accepting new call');
        _cleanup().then((_) {
          _processIncomingCall(data);
        }).catchError((e) {
          print('Error cleaning up before incoming call: $e');
          _forceCleanup();
          _processIncomingCall(data);
        });
      }
    } catch (e) {
      print('CallService: Error handling incoming call: $e');
      _forceCleanup();
      _callState = CallState.idle;
      onCallStateChanged?.call(_callState);
      onCallError?.call('Error handling incoming call: $e');
    }
  }
  
  /// Force immediate cleanup without async operations
  void _forceCleanup({bool preserveRejectedState = false}) {
    print('CallService: Force cleaning up call state (preserveRejectedState: $preserveRejectedState)');
    
    // Stop all tracks immediately
    try {
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });
    } catch (e) {
      print('Error stopping tracks during force cleanup: $e');
    }
    
    // Dispose streams asynchronously (fire and forget)
    _localStream?.dispose().catchError((e) {
      print('Error disposing local stream: $e');
    });
    _remoteStream?.dispose().catchError((e) {
      print('Error disposing remote stream: $e');
    });
    
    // Close peer connection asynchronously (fire and forget)
    if (_peerConnection != null) {
      _peerConnection!.close().catchError((e) {
        print('Error closing peer connection: $e');
      });
    }
    
    // Reset all state immediately
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _currentConversationId = null;
    _otherUserId = null;
    _currentCallType = null;
    _callStartTime = null;
    _callConnectedTime = null;
    _storedIncomingCallData = null;
    _isRecording = false;
    _isSpeakerEnabled = false;
    
    // Only reset to idle if not preserving rejected state
    if (!preserveRejectedState) {
      _callState = CallState.idle;
      onCallStateChanged?.call(_callState);
    }
    print('CallService: Force cleanup complete - state: $_callState');
  }
  
  /// Clean up resources without resetting state
  void _cleanupResources() {
    print('CallService: Cleaning up call resources');
    
    // Stop all tracks immediately
    try {
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });
    } catch (e) {
      print('Error stopping tracks: $e');
    }
    
    // Dispose streams asynchronously (fire and forget)
    _localStream?.dispose().catchError((e) {
      print('Error disposing local stream: $e');
    });
    _remoteStream?.dispose().catchError((e) {
      print('Error disposing remote stream: $e');
    });
    
    // Close peer connection asynchronously (fire and forget)
    if (_peerConnection != null) {
      _peerConnection!.close().catchError((e) {
        print('Error closing peer connection: $e');
      });
    }
    
    // Clear resources but keep state
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _storedIncomingCallData = null;
    _isRecording = false;
    _isSpeakerEnabled = false;
    
    print('CallService: Resources cleaned up');
  }
  
  void _processIncomingCall(Map<String, dynamic> data) {
    // Store incoming call data
    _currentCallId = data['callId']?.toString();
    _currentConversationId = data['conversationId']?.toString();
    _otherUserId = data['callerId']?.toString();
    _currentCallType = data['callType'] == 'video' ? CallType.video : CallType.voice;
    _callStartTime = DateTime.now(); // Track when incoming call started
    
    // Store the full incoming call data for later use
    _storedIncomingCallData = Map<String, dynamic>.from(data);
    
    // Set state to ringing
    _callState = CallState.ringing;
    onCallStateChanged?.call(_callState);
    
    // Trigger incoming call callback
    onIncomingCall?.call(data);
    print('CallService: Incoming call processed - callId: $_currentCallId, state: $_callState');
  }
  
  void _handleCallAccepted(Map<String, dynamic> data) {
    if (data['callId'] == _currentCallId) {
      _callState = CallState.connected;
      _callConnectedTime = DateTime.now(); // Track when call was connected
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
    final rejectedCallId = data['callId']?.toString();
    print('CallService: Call rejected event received - callId: $rejectedCallId, currentCallId: $_currentCallId, currentState: $_callState');
    
    // Always handle rejection if we're in any active call state (calling, ringing, connected)
    // This ensures the caller's device stops showing "calling" when the call is rejected
    final isActiveCallState = _callState == CallState.calling || 
                             _callState == CallState.ringing || 
                             _callState == CallState.connected;
    final isMatchingCallId = rejectedCallId == _currentCallId && _currentCallId != null;
    
    // Handle rejection if we're in an active call state, or if call IDs match, or if we're not idle
    // This ensures the caller's device always stops calling when rejection is received
    if (isActiveCallState || isMatchingCallId || _callState != CallState.idle) {
      print('CallService: Call rejected by other party - setting state to rejected');
      // Set state to rejected first for UI feedback
      _callState = CallState.rejected;
      onCallStateChanged?.call(_callState);
      
      // Clean up resources immediately but keep rejected state visible
      _cleanupResources();
      
      // After a delay, reset to idle (UI will have shown rejected state)
      Future.delayed(const Duration(seconds: 2), () {
        if (_callState == CallState.rejected) {
          _currentCallId = null;
          _currentConversationId = null;
          _otherUserId = null;
          _currentCallType = null;
          _callStartTime = null;
          _callConnectedTime = null;
          _callState = CallState.idle;
          onCallStateChanged?.call(_callState);
          print('CallService: Rejected state cleared, reset to idle');
        }
      });
    } else {
      print('CallService: Rejection event but already in idle state - ignoring');
    }
  }
  
  void _handleCallEnded(Map<String, dynamic> data) {
    final endedCallId = data['callId']?.toString();
    print('CallService: Call ended event received - callId: $endedCallId, currentCallId: $_currentCallId');
    
    // Handle end if it matches current call or if we're in any active call state
    if (endedCallId == _currentCallId || 
        _callState == CallState.connected ||
        _callState == CallState.calling ||
        _callState == CallState.ringing) {
      print('CallService: Call ended by other party - force cleaning up');
      // Force immediate cleanup
      _forceCleanup();
    } else {
      print('CallService: End event for different call or wrong state - force cleaning up anyway');
      // Even if call ID doesn't match, if we're in a call state, clean up
      if (_callState != CallState.idle) {
        _forceCleanup();
      }
    }
  }
  
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      if (data['callId'] == _currentCallId && _peerConnection != null && data['candidate'] != null) {
        final candidate = webrtc.RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }
  
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      if (data['callId'] == _currentCallId && _peerConnection != null && data['offer'] != null) {
        final offer = webrtc.RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );
        await _peerConnection!.setRemoteDescription(offer);
        
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        
        if (_socket != null && _socket!.connected && _currentCallId != null) {
          _socket!.emit('answer', {
            'callId': _currentCallId,
            'answer': {
              'type': answer.type,
              'sdp': answer.sdp,
            },
          });
        }
      }
    } catch (e) {
      print('Error handling offer: $e');
    }
  }
  
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      if (data['callId'] == _currentCallId && _peerConnection != null && data['answer'] != null) {
        final answer = webrtc.RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _peerConnection!.setRemoteDescription(answer);
      }
    } catch (e) {
      print('Error handling answer: $e');
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
    print('CallService: Starting cleanup...');
    // Clear stored incoming call data
    _storedIncomingCallData = null;
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
      // Reset all state
      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      _currentCallId = null;
      _currentConversationId = null;
      _otherUserId = null;
      _currentCallType = null;
      _callStartTime = null;
      _callConnectedTime = null;
      _isRecording = false;
      _isSpeakerEnabled = false;
      
      // Always reset to idle after cleanup to allow new calls
      _callState = CallState.idle;
      onCallStateChanged?.call(_callState);
      print('CallService: Cleanup complete, state reset to idle');
    }
  }
  
  void dispose() {
    _cleanup();
  }
}

