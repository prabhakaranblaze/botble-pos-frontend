import 'package:martfury/src/model/notification.dart';
import 'package:martfury/src/service/base_service.dart';

class NotificationApiService extends BaseService {
  static const String _notificationsEndpoint = '/api/v1/notifications';

  Future<NotificationListResponse> getNotifications({int page = 1}) async {
    try {
      final response = await get('$_notificationsEndpoint?page=$page');
      
      
      return NotificationListResponse.fromJson(response);
    } catch (e) {
      return NotificationListResponse(
        data: [],
        error: true,
        message: e.toString(),
      );
    }
  }

  Future<NotificationStats> getNotificationStats() async {
    try {
      final response = await get('$_notificationsEndpoint/stats');
      if (response['data'] != null) {
        return NotificationStats.fromJson(response['data']);
      }
      return NotificationStats(total: 0, unread: 0, unclicked: 0);
    } catch (e) {
      return NotificationStats(total: 0, unread: 0, unclicked: 0);
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await post('$_notificationsEndpoint/$notificationId/read', {});
      return response['error'] == false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markNotificationAsClicked(String notificationId) async {
    try {
      final response = await post('$_notificationsEndpoint/$notificationId/clicked', {});
      return response['error'] == false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await post('$_notificationsEndpoint/mark-all-read', {});
      return response['error'] == false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await delete('$_notificationsEndpoint/$notificationId', {});
      return response['error'] == false;
    } catch (e) {
      return false;
    }
  }
}