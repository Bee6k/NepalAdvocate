import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications({
    bool? isRead,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (isRead != null) {
        queryParams['isRead'] = isRead.toString();
      }

      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final notificationsData = response.data['data']['notifications'] as List;
        return notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: {'isRead': 'false', 'limit': '1'},
      );

      if (response.data['success'] == true) {
        return response.data['data']['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.patch(
        '${ApiConstants.notifications}/$notificationId/read',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.patch('${ApiConstants.notifications}/read-all');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      await _apiClient.delete('${ApiConstants.notifications}/clear-all');
    } catch (e) {
      rethrow;
    }
  }
}

