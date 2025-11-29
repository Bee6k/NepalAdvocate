import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/call_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/call_service.dart';
import '../../services/local_notification_service.dart';
import '../../views/calls/call_screen.dart';
import '../../core/utils/api_client.dart';
import '../../models/user_model.dart';
import 'client_dashboard.dart';
import 'lawyer_dashboard.dart';
import 'admin_dashboard.dart';
import '../appointments/appointment_booking_screen.dart';
import '../documents/document_upload_screen.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import '../lawyers/lawyer_list_screen.dart';
import '../templates/templates_list_screen.dart';
import '../clients/lawyer_clients_screen.dart';

class DashboardWrapper extends ConsumerStatefulWidget {
  final String userRole;
  
  const DashboardWrapper({super.key, required this.userRole});

  @override
  ConsumerState<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends ConsumerState<DashboardWrapper> {
  int _currentIndex = 0;
  CallService? _callService;
  String? _currentConversationId; // Track current chat conversation

  @override
  void initState() {
    super.initState();
    _setupCallListener();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setupNotificationListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final chatService = ref.read(chatServiceProvider);
        
        // Ensure socket is connected
        if (!chatService.isConnected) {
          await chatService.connect();
        }

        // Listen for notifications
        chatService.onNotification((notification) {
          if (!mounted) return;
          
          // Extract notification data
          final title = notification['title'] ?? 'Notification';
          final message = notification['message'] ?? '';
          final type = notification['type'] ?? 'SYSTEM';
          final notificationId = notification['_id'] ?? notification['id'] ?? '';
          final relatedId = notification['relatedId'];
          
          // Show OS notification
          _showLocalNotification(
            id: notificationId.hashCode,
            title: title,
            body: message,
            type: type,
            payload: relatedId != null ? 'notification:$notificationId' : null,
          );
          
          // Play notification sound
          _playNotificationSound();
          
          // Refresh notifications list
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
          
          print('Notification received: $title - $message');
        });

        // Listen for appointment events (emitted as appointment:userId)
        // The backend emits to all sockets, so we listen and check if it's for current user
        final currentUserId = ref.read(authControllerProvider).user?.id;
        if (currentUserId != null && chatService.isConnected) {
          // Listen for appointment events - backend emits to all, we filter by checking appointment participants
          chatService.socket?.on('appointment:$currentUserId', (data) {
            if (!mounted) return;
            
            // Extract appointment data
            final type = data['type'] ?? 'APPOINTMENT_REQUEST';
            final appointment = data['appointment'];
            
            // Create notification title and message based on type
            String title = 'Appointment Update';
            String message = 'You have a new appointment update';
            
            switch (type) {
              case 'APPOINTMENT_REQUEST':
                title = 'New Appointment Request';
                message = 'You have received a new appointment request';
                break;
              case 'APPOINTMENT_PROPOSED':
                title = 'Appointment Time Proposed';
                message = 'A new time has been proposed for your appointment';
                break;
              case 'APPOINTMENT_CONFIRMED':
                title = 'Appointment Confirmed';
                message = 'Your appointment has been confirmed';
                break;
              case 'APPOINTMENT_CANCELLED':
                title = 'Appointment Cancelled';
                message = 'An appointment has been cancelled';
                break;
            }
            
            // Show OS notification
            final appointmentId = appointment?['_id'] ?? appointment?['id'] ?? '';
            _showLocalNotification(
              id: 'appointment:$appointmentId'.hashCode,
              title: title,
              body: message,
              type: type,
              payload: appointmentId != null && appointmentId.toString().isNotEmpty 
                  ? 'appointment:$appointmentId' 
                  : null,
            );
            
            // Play notification sound
            _playNotificationSound();
            
            // Refresh notifications list
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadCountProvider);
            
            print('Appointment event received: $type');
          });
        }

        // Listen for new messages (play sound if not in current chat)
        chatService.onMessage((message) {
          if (!mounted) return;
          
          // Only play sound if message is not from current conversation
          final messageConvId = message.conversationId?.toString() ?? '';
          if (messageConvId != _currentConversationId) {
            _playMessageSound();
            print('New message received from different conversation');
          }
        });
      } catch (e) {
        print('Error setting up notification listener: $e');
      }
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await FlutterRingtonePlayer().playNotification();
    } catch (e) {
      print('Error playing notification sound: $e');
      // Fallback: try playing as alarm
      try {
        await FlutterRingtonePlayer().playAlarm();
      } catch (e2) {
        print('Error playing alarm sound: $e2');
      }
    }
  }

  Future<void> _playMessageSound() async {
    try {
      // Use a different sound for messages (notification sound)
      await FlutterRingtonePlayer().playNotification();
    } catch (e) {
      print('Error playing message sound: $e');
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String type,
    String? payload,
  }) async {
    try {
      await LocalNotificationService().showNotification(
        id: id,
        title: title,
        body: body,
        notificationType: type,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  void _setupCallListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final callService = ref.read(callServiceProvider);
      final chatService = ref.read(chatServiceProvider);
      _callService = callService;
      
      // Set up chat message handler for call service
      callService.setChatMessageHandler((conversationId, content, messageType) {
        if (chatService.isConnected) {
          chatService.sendMessage(
            conversationId: conversationId,
            content: content,
            messageType: messageType,
          );
        }
      });
      
      // Ensure call service socket is connected
      if (!callService.isConnected) {
        try {
          await callService.connect();
        } catch (e) {
          print('Error connecting call service: $e');
        }
      }
      
      // Set up incoming call handler
      callService.onIncomingCall = (data) async {
        print('DashboardWrapper: Incoming call received: $data');
        if (!mounted) return;
        
        try {
          // Fetch caller information
          final callerId = data['callerId'];
          final callType = data['callType'] == 'video' ? 'Video' : 'Voice';
          UserModel? caller;
          
          if (callerId != null) {
            try {
              final response = await ApiClient().dio.get('/auth/user/$callerId');
              if (response.data['success'] == true && response.data['data'] != null) {
                caller = UserModel.fromJson(response.data['data']['user']);
              }
            } catch (e) {
              print('Error fetching caller info: $e');
              // Create a basic user model if fetch fails
              caller = UserModel(
                id: callerId,
                email: '',
                role: 'CLIENT',
                firstName: 'Unknown',
                lastName: 'User',
              );
            }
          } else {
            // Create a basic user model if no caller ID
            caller = UserModel(
              id: '',
              email: '',
              role: 'CLIENT',
              firstName: 'Unknown',
              lastName: 'User',
            );
          }
          
          // Show OS notification for incoming call
          final callerName = '${caller?.firstName ?? 'Unknown'} ${caller?.lastName ?? 'User'}'.trim();
          await _showLocalNotification(
            id: 'incoming_call_${data['callId']}'.hashCode,
            title: 'Incoming $callType Call',
            body: '$callerName is calling you...',
            type: 'INCOMING_CALL',
            payload: 'call:${data['callId']}',
          );
          
          // Set other user in call controller
          final callController = ref.read(callControllerProvider.notifier);
          callController.setOtherUser(caller);
          
          // Store incoming call data in call controller
          // The call service should have already set the state to ringing
          // but we ensure the data is available
          
            // Navigate to call screen
          if (mounted) {
            // Small delay to ensure state is set
            await Future.delayed(const Duration(milliseconds: 100));
            
            // Check if we're already showing a call screen
            final navigator = Navigator.of(context);
            final isCallScreenActive = navigator.canPop() && 
                ModalRoute.of(context)?.settings.name?.contains('CallScreen') == true;
            
            if (!isCallScreenActive) {
              // Navigate to call screen
              await navigator.push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    conversationId: data['conversationId'] ?? '',
                    otherUserId: callerId ?? '',
                    callType: data['callType'] == 'video' ? CallType.video : CallType.voice,
                    isIncoming: true,
                  ),
                ),
              );
            } else {
              print('Call screen already active, not navigating again');
            }
          }
        } catch (e) {
          print('Error handling incoming call: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error receiving call: ${e.toString()}'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      };
      
      // Re-setup listener when socket reconnects
      callService.onConnect = () {
        print('DashboardWrapper: Call service socket reconnected, ensuring listener is active');
        // The listener is already set above, but we can verify it's still set
        if (callService.onIncomingCall == null) {
          print('Warning: Incoming call listener was lost, re-setting...');
          // Re-set the listener if it was lost
        }
      };
      
      // Verify socket is listening
      print('DashboardWrapper: Call listener set up. Socket connected: ${callService.isConnected}');
    });
  }

  List<Widget> _getScreens() {
    switch (widget.userRole) {
      case 'CLIENT':
        return [
          ClientDashboard(),
          LawyerListScreen(),
          TemplatesListScreen(),
          SettingsScreen(),
        ];
      case 'LAWYER':
        return [
          LawyerDashboard(),
          LawyerClientsScreen(),
          SettingsScreen(),
        ];
      case 'ADMIN':
        return [
          AdminDashboard(),
          TemplatesListScreen(),
          SettingsScreen(),
        ];
      default:
        return [ClientDashboard()];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    switch (widget.userRole) {
      case 'CLIENT':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Lawyers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Templates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case 'LAWYER':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case 'ADMIN':
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Templates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final navItems = _getNavItems();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.surfaceColor,
        items: navItems,
      ),
    );
  }
}

