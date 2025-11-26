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
      _incomingCallData = data;
      state = CallState.ringing;
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
    if (_incomingCallData == null) return;
    try {
      await _callService.acceptCall(_incomingCallData!);
      _incomingCallData = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectCall() async {
    await _callService.rejectCall();
    _incomingCallData = null;
    state = CallState.idle;
  }

  Future<void> endCall() async {
    await _callService.endCall();
    _incomingCallData = null;
    state = CallState.idle;
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

