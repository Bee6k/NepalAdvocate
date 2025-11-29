import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permissions
    await _requestPermissions();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin with background handler
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _initialized = true;
    print('✅ Local Notification Service initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires notification permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
      'appointments',
      'Appointments',
      description: 'Notifications for appointment updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel messageChannel = AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general',
      'General',
      description: 'General notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const AndroidNotificationChannel incomingCallChannel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'Notifications for incoming calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(appointmentChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messageChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incomingCallChannel);
  }

  /// Get notification channel ID based on notification type
  String _getChannelId(String notificationType) {
    switch (notificationType) {
      case 'APPOINTMENT_REQUEST':
      case 'APPOINTMENT_PROPOSED':
      case 'APPOINTMENT_CONFIRMED':
      case 'APPOINTMENT_CANCELLED':
        return 'appointments';
      case 'MESSAGE':
        return 'messages';
      case 'INCOMING_CALL':
        return 'incoming_calls';
      default:
        return 'general';
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? notificationType,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final channelId = _getChannelId(notificationType ?? 'SYSTEM');

    // Determine channel name and description
    String channelName;
    String channelDescription;
    Importance importance;
    
    switch (channelId) {
      case 'appointments':
        channelName = 'Appointments';
        channelDescription = 'Notifications for appointment updates';
        importance = Importance.high;
        break;
      case 'messages':
        channelName = 'Messages';
        channelDescription = 'Notifications for new messages';
        importance = Importance.high;
        break;
      case 'incoming_calls':
        channelName = 'Incoming Calls';
        channelDescription = 'Notifications for incoming calls';
        importance = Importance.max;
        break;
      default:
        channelName = 'General';
        channelDescription = 'General notifications';
        importance = Importance.high;
    }

    // Android notification details - use dynamic channel
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    print('📱 Local notification shown: $title');
  }

  /// Handle notification tap (foreground)
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped (foreground): ${response.payload}');
    // Handle navigation based on payload
    // This will be handled by the app's navigation logic
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}

/// Handle background notification tap (must be top-level function)
@pragma('vm:entry-point')
void onBackgroundNotificationTapped(NotificationResponse response) {
  print('🔔 Notification tapped (background): ${response.payload}');
  // Handle background notification tap
  // The app will be launched when user taps the notification
}

