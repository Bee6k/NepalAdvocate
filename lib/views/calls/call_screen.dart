import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../controllers/call_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/call_service.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/verified_avatar.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final CallType callType;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.callType,
    this.isIncoming = false,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  webrtc.RTCVideoRenderer? _localRenderer;
  webrtc.RTCVideoRenderer? _remoteRenderer;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  bool _isRinging = false;
  bool _isSpeakerEnabled = false;
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _hasShownEndedState = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start ringing when call state becomes ringing (for incoming calls)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callState = ref.read(callControllerProvider);
      if (callState == CallState.ringing && !_isRinging) {
        _startRinging();
      }
    });
  }

  Future<void> _startRinging() async {
    if (!mounted) return;
    
    setState(() {
      _isRinging = true;
    });
    
    try {
      // Play ringtone - use system ringtone
      await FlutterRingtonePlayer().playRingtone(
        asAlarm: false,
      );
    } catch (e) {
      print('Error playing ringtone: $e');
      // Fallback: try Android ringtone only
      try {
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.ringtone,
          looping: true,
          volume: 1.0,
        );
      } catch (e2) {
        print('Error playing fallback ringtone: $e2');
      }
    }
  }

  Future<void> _stopRinging() async {
    if (!_isRinging) return;
    
    setState(() {
      _isRinging = false;
    });
    
    try {
      await FlutterRingtonePlayer().stop();
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }

  Future<bool> _requestPermissions(CallType callType) async {
    try {
      // Check microphone permission status first
      final micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          print('Microphone permission denied: $result');
          return false;
        }
      } else if (micStatus.isPermanentlyDenied) {
        print('Microphone permission permanently denied');
        return false;
      } else if (!micStatus.isGranted) {
        print('Microphone permission not granted: $micStatus');
        return false;
      }

      // Check camera permission if it's a video call
      if (callType == CallType.video) {
        final cameraStatus = await Permission.camera.status;
        if (cameraStatus.isDenied) {
          final result = await Permission.camera.request();
          if (!result.isGranted) {
            print('Camera permission denied: $result');
            return false;
          }
        } else if (cameraStatus.isPermanentlyDenied) {
          print('Camera permission permanently denied');
          return false;
        } else if (!cameraStatus.isGranted) {
          print('Camera permission not granted: $cameraStatus');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> _initializeRenderers() async {
    try {
      _localRenderer = webrtc.RTCVideoRenderer();
      _remoteRenderer = webrtc.RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing renderers: $e');
      // Try to reinitialize if failed
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && _localRenderer == null && _remoteRenderer == null) {
          await _initializeRenderers();
        }
      } catch (e2) {
        print('Error reinitializing renderers: $e2');
      }
    }
  }

  @override
  void dispose() {
    _stopRinging();
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callControllerProvider);
    final callController = ref.read(callControllerProvider.notifier);
    final currentUser = ref.watch(authControllerProvider).user;
    final otherUser = callController.otherUser;

    // Start call if not incoming
    if (!widget.isIncoming && callState == CallState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Request permissions first before starting call
          final hasPermissions = await _requestPermissions(widget.callType);
          if (!hasPermissions) {
            if (mounted) {
              // Check if permissions are permanently denied
              final micStatus = await Permission.microphone.status;
              final cameraStatus = widget.callType == CallType.video 
                  ? await Permission.camera.status 
                  : PermissionStatus.granted;
              
              final isPermanentlyDenied = micStatus.isPermanentlyDenied || 
                  (widget.callType == CallType.video && cameraStatus.isPermanentlyDenied);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isPermanentlyDenied
                        ? 'Please enable camera/microphone permissions in Settings'
                        : 'Camera/Microphone permissions are required for calls',
                  ),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () async {
                      await openAppSettings();
                    },
                  ),
                ),
              );
            }
            if (mounted) {
              Navigator.pop(context);
            }
            return;
          }

          await callController.startCall(
            widget.conversationId,
            widget.otherUserId,
            widget.callType,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start call: ${e.toString()}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            Navigator.pop(context);
          }
        }
      });
    }

    // Update video renderers when streams change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localStream = callController.localStream;
      final remoteStream = callController.remoteStream;
      
      if (localStream != null && _localRenderer != null) {
        if (_localRenderer!.srcObject != localStream) {
          _localRenderer!.srcObject = localStream;
          setState(() {}); // Force rebuild to show video
        }
        // Sync mute/video state from actual tracks
        final audioTracks = localStream.getAudioTracks();
        final videoTracks = localStream.getVideoTracks();
        if (audioTracks.isNotEmpty) {
          final isMuted = !audioTracks[0].enabled!;
          if (_isMuted != isMuted) {
            setState(() => _isMuted = isMuted);
          }
        }
        if (videoTracks.isNotEmpty) {
          final isVideoEnabled = videoTracks[0].enabled!;
          if (_isVideoEnabled != isVideoEnabled) {
            setState(() => _isVideoEnabled = isVideoEnabled);
          }
        }
      }
      if (remoteStream != null && _remoteRenderer != null) {
        if (_remoteRenderer!.srcObject != remoteStream) {
          _remoteRenderer!.srcObject = remoteStream;
          setState(() {}); // Force rebuild to show video
        }
      }
      
      // Handle incoming call ringing state
      if (callState == CallState.ringing && !_isRinging) {
        _startRinging();
      } else if (callState != CallState.ringing && _isRinging) {
        _stopRinging();
      }
      
      // Sync recording and speaker state
      if (callState == CallState.connected) {
        final isRecording = callController.isRecording;
        final isSpeakerEnabled = callController.isSpeakerEnabled;
        if (_isRecording != isRecording || _isSpeakerEnabled != isSpeakerEnabled) {
          setState(() {
            _isRecording = isRecording;
            _isSpeakerEnabled = isSpeakerEnabled;
          });
        }
      }
      
      // Handle call ended state - show ended UI and auto-navigate after delay
      if ((callState == CallState.ended || callState == CallState.rejected) && !_hasShownEndedState) {
        _hasShownEndedState = true;
        // Auto-navigate back after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });

    final isVideoCall = callController.callType == CallType.video || widget.callType == CallType.video;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen for video calls)
            if (isVideoCall)
              Positioned.fill(
                child: _remoteRenderer != null && callController.remoteStream != null
                    ? webrtc.RTCVideoView(
                        _remoteRenderer!,
                        objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: false,
                      )
                    : Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              VerifiedAvatar(
                                imageUrl: otherUser?.profilePicture,
                                name: otherUser?.fullName,
                                radius: 60,
                                isVerified: false,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                otherUser?.fullName ?? 'Connecting...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getCallStateText(callState),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              )
            else
              // Voice call UI
              _buildVoiceCallUI(otherUser, callState),

            // Local video (small overlay for video calls)
            if (isVideoCall && _localRenderer != null && callController.localStream != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    // Optional: Tap to swap video positions
                  },
                  child: Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          webrtc.RTCVideoView(
                            _localRenderer!,
                            objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            mirror: true, // Mirror local video
                          ),
                          // Show mute indicator overlay
                          if (_isMuted)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Icon(
                                  Icons.mic_off,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Call controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCallControls(callState, callController, currentUser),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCallUI(UserModel? otherUser, CallState callState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VerifiedAvatar(
            imageUrl: otherUser?.profilePicture,
            name: otherUser?.fullName,
            radius: 80,
            isVerified: false,
          ),
          const SizedBox(height: 32),
          Text(
            otherUser?.fullName ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getCallStateText(callState),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(CallState callState, CallController callController, UserModel? currentUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (callState == CallState.ringing)
            // Incoming call controls - simple accept/reject buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject button
                _buildCallButton(
                  icon: Icons.call_end,
                  color: AppTheme.errorColor,
                  size: 70,
                  onPressed: () async {
                    await _stopRinging();
                    await callController.rejectCall();
                    if (mounted) Navigator.pop(context);
                  },
                ),
                // Accept button
                _buildCallButton(
                  icon: Icons.call,
                  color: AppTheme.primaryColor,
                  size: 70,
                  onPressed: () async {
                    await _stopRinging();
                    try {
                      // Request permissions before accepting
                      final hasPermissions = await _requestPermissions(widget.callType);
                      if (!hasPermissions) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Camera/Microphone permissions are required for calls'),
                              backgroundColor: AppTheme.errorColor,
                              action: SnackBarAction(
                                label: 'Settings',
                                textColor: Colors.white,
                                onPressed: () async {
                                  await openAppSettings();
                                },
                              ),
                            ),
                          );
                        }
                        await callController.rejectCall();
                        if (mounted) Navigator.pop(context);
                        return;
                      }

                      await callController.acceptCall();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to accept call: ${e.toString()}'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ],
            )
          else if (callState == CallState.connected)
            // Active call controls
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // First row - Main controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? AppTheme.errorColor : Colors.grey[800]!,
                      size: 60,
                      onPressed: () async {
                        try {
                          await callController.toggleMute();
                          // State will be synced from stream tracks in postFrameCallback
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to toggle mute: ${e.toString()}'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    if (callController.callType == CallType.video || widget.callType == CallType.video) ...[
                      _buildCallButton(
                        icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        color: _isVideoEnabled ? Colors.grey[800]! : AppTheme.errorColor,
                        size: 60,
                        onPressed: () async {
                          try {
                            await callController.toggleVideo();
                            // State will be synced from stream tracks in postFrameCallback
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to toggle video: ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildCallButton(
                        icon: Icons.flip_camera_ios,
                        color: Colors.grey[800]!,
                        size: 60,
                        onPressed: () async {
                          await callController.switchCamera();
                          setState(() {
                            _isFrontCamera = !_isFrontCamera;
                          });
                        },
                      ),
                    ] else ...[
                      // Switch to video button for voice calls
                      _buildCallButton(
                        icon: Icons.videocam,
                        color: AppTheme.primaryColor,
                        size: 60,
                        onPressed: () async {
                          try {
                            // Request camera permission
                            final cameraStatus = await Permission.camera.status;
                            if (cameraStatus.isDenied) {
                              final result = await Permission.camera.request();
                              if (!result.isGranted) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Camera permission is required for video call'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                }
                                return;
                              }
                            }
                            
                            await callController.switchToVideo();
                            if (mounted) {
                              setState(() {
                                _isVideoEnabled = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switching to video call...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to switch to video: ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                    _buildCallButton(
                      icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                      color: _isSpeakerEnabled ? AppTheme.primaryColor : Colors.grey[800]!,
                      size: 60,
                      onPressed: () async {
                        try {
                          await callController.toggleSpeaker();
                          // Update state after toggle
                          setState(() {
                            _isSpeakerEnabled = callController.isSpeakerEnabled;
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to toggle speaker: ${e.toString()}'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildCallButton(
                      icon: Icons.call_end,
                      color: AppTheme.errorColor,
                      size: 70,
                      onPressed: () async {
                        if (_isRecording) {
                          await callController.stopRecording();
                        }
                        await callController.endCall();
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                // Second row - Additional controls (for lawyers)
                if (ref.watch(authControllerProvider).user?.role == 'LAWYER') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCallButton(
                        icon: _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
                        color: _isRecording ? AppTheme.errorColor : Colors.red,
                        size: 50,
                        onPressed: () async {
                          try {
                            if (_isRecording) {
                              await callController.stopRecording();
                              if (mounted) {
                                setState(() {
                                  _isRecording = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Recording stopped'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              await callController.startRecording();
                              if (mounted) {
                                setState(() {
                                  _isRecording = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Recording started'),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.grey[900],
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to ${_isRecording ? 'stop' : 'start'} recording: ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isRecording ? 'Recording...' : 'Record Call',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            )
          else if (callState == CallState.calling)
            // Calling state
            Center(
              child: _buildCallButton(
                icon: Icons.call_end,
                color: AppTheme.errorColor,
                size: 70,
                onPressed: () async {
                  await callController.endCall();
                  if (mounted) Navigator.pop(context);
                },
              ),
            )
          else if (callState == CallState.ended || callState == CallState.rejected)
            // Call ended state
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _getCallStateText(callState),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Go Back text (priority) - tappable
                  GestureDetector(
                    onTap: () {
                      if (mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Go Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Optional button as secondary option
                  _buildCallButton(
                    icon: Icons.close,
                    color: Colors.grey[800]!,
                    size: 50,
                    onPressed: () {
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double? size,
  }) {
    final buttonSize = size ?? 64.0;
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonSize / 2),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: (buttonSize * 0.4).clamp(24.0, 32.0),
            ),
          ),
        ),
      ),
    );
  }

  String _getCallStateText(CallState state) {
    switch (state) {
      case CallState.calling:
        return 'Calling...';
      case CallState.ringing:
        return widget.isIncoming ? 'Incoming call' : 'Ringing...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
      case CallState.rejected:
        return 'Call rejected';
      case CallState.busy:
        return 'Busy';
      default:
        return '';
    }
  }
}

