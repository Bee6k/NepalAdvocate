import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return ref.read(notificationServiceProvider).getNotifications();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.read(notificationServiceProvider).getUnreadCount();
});

