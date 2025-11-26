import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/call_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/call_service.dart';
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
          
          // Play notification sound
          _playNotificationSound();
          
          // Refresh notifications list
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
          
          print('Notification received: ${notification['title']} - ${notification['message']}');
        });

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

  void _setupCallListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callService = ref.read(callServiceProvider);
      _callService = callService;
      
      callService.onIncomingCall = (data) async {
        if (!mounted) return;
        
        try {
          // Fetch caller information
          final callerId = data['callerId'];
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
          
          // Set other user in call controller
          final callController = ref.read(callControllerProvider.notifier);
          callController.setOtherUser(caller);
          
          // Navigate to call screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  conversationId: data['conversationId'] ?? '',
                  otherUserId: callerId ?? '',
                  callType: data['callType'] == 'video' ? CallType.video : CallType.voice,
                  isIncoming: true,
                ),
              ),
            );
          }
        } catch (e) {
          print('Error handling incoming call: $e');
        }
      };
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

