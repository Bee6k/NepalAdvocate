import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../services/call_service.dart';
import '../models/user_model.dart';

class CallController extends StateNotifier<CallState> {
  final CallService _callService;
  Map<String, dynamic>? _incomingCallData;
  UserModel? _otherUser;

  CallController(this._callService) : super(CallState.idle) {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _callService.onCallStateChanged = (state) {
      this.state = state;
    };

    _callService.onIncomingCall = (data) {
      print('CallController: Received incoming call data: $data');
      // Store the incoming call data with offer
      _incomingCallData = Map<String, dynamic>.from(data);
      state = CallState.ringing;
      print('CallController: Stored incoming call data, offer present: ${_incomingCallData?['offer'] != null}');
    };

    _callService.onCallError = (error) {
      // Handle error
      print('Call error: $error');
    };
  }

  Map<String, dynamic>? get incomingCallData => _incomingCallData;
  UserModel? get otherUser => _otherUser;
  CallType? get callType => _callService.callType;
  dynamic get localStream => _callService.localStream;
  dynamic get remoteStream => _callService.remoteStream;

  Future<void> startCall(String conversationId, String otherUserId, CallType callType) async {
    try {
      await _callService.startCall(conversationId, otherUserId, callType);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptCall() async {
    // Try to get incoming call data from multiple sources
    Map<String, dynamic>? callData;
    
    // First, try stored incoming call data in controller
    if (_incomingCallData != null && _incomingCallData!['offer'] != null) {
      callData = Map<String, dynamic>.from(_incomingCallData!);
    } else {
      // Try to get from call service stored data
      final serviceData = _callService.storedIncomingCallData;
      if (serviceData != null && serviceData['offer'] != null) {
        callData = Map<String, dynamic>.from(serviceData);
        // Also update controller's stored data
        _incomingCallData = callData;
      }
    }
    
    // If still no data, check if we can construct it from service
    if (callData == null) {
      final callId = _callService.callId;
      final conversationId = _callService.conversationId;
      final callType = _callService.callType;
      
      if (callId == null || conversationId == null || callType == null) {
        throw Exception('No incoming call data available. Please wait for the call to be received.');
      }
      
      // If we don't have the offer, we can't accept
      throw Exception('Call offer not available. The incoming call may have expired or was not received properly.');
    }
    
    // Validate required fields
    if (callData['callId'] == null) {
      throw Exception('Call ID is missing');
    }
    if (callData['offer'] == null) {
      print('Call data available but offer is missing: $callData');
      throw Exception('Call offer is missing. Cannot accept call.');
    }
    
    // Ensure callerId is set
    if (callData['callerId'] == null && _otherUser != null) {
      callData['callerId'] = _otherUser!.id;
    }
    
    try {
      await _callService.acceptCall(callData);
      _incomingCallData = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectCall() async {
    print('CallController: Rejecting call');
    await _callService.rejectCall();
    _incomingCallData = null;
    // State will be set to idle by the service cleanup, but ensure it here too
    state = CallState.idle;
    print('CallController: Call rejected, state reset to idle');
  }

  Future<void> endCall() async {
    print('CallController: Ending call');
    await _callService.endCall();
    _incomingCallData = null;
    // State will be set to idle by the service cleanup, but ensure it here too
    state = CallState.idle;
    print('CallController: Call ended, state reset to idle');
  }

  Future<void> toggleMute() async {
    await _callService.toggleMute();
  }

  Future<void> toggleVideo() async {
    await _callService.toggleVideo();
  }

  Future<void> switchCamera() async {
    await _callService.switchCamera();
  }

  Future<void> switchToVideo() async {
    await _callService.switchToVideo();
  }

  Future<void> toggleSpeaker() async {
    await _callService.toggleSpeaker();
  }

  Future<void> startRecording() async {
    await _callService.startRecording();
  }

  Future<void> stopRecording() async {
    await _callService.stopRecording();
  }

  bool get isSpeakerEnabled => _callService.isSpeakerEnabled;
  bool get isRecording => _callService.isRecording;

  void setOtherUser(UserModel? user) {
    _otherUser = user;
  }
}

final callServiceProvider = Provider<CallService>((ref) {
  final service = CallService();
  ref.onDispose(() => service.dispose());
  return service;
});

final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) {
  return CallController(ref.read(callServiceProvider));
});

