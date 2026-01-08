import 'package:get/get.dart';
import 'package:martfury/src/model/notification.dart';
import 'package:martfury/src/service/notification_api_service.dart';
import 'package:martfury/src/service/token_service.dart';

class NotificationController extends GetxController {
  final NotificationApiService _notificationService = NotificationApiService();

  // Reactive state variables
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  final notifications = <Notification>[].obs;
  final notificationStats = Rxn<NotificationStats>();
  final currentPage = 1.obs;
  final hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthAndLoadData();
  }

  Future<void> checkAuthAndLoadData() async {
    final token = await TokenService.getToken();
    if (token != null) {
      loadNotifications();
      loadNotificationStats();
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
      notifications.clear();
    }

    if (!hasMore.value) return;

    if (currentPage.value == 1) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }
    
    error.value = null;

    try {
      final response = await _notificationService.getNotifications(
        page: currentPage.value,
      );

      if (!response.error) {
        if (currentPage.value == 1) {
          notifications.assignAll(response.data);
        } else {
          notifications.addAll(response.data);
        }

        // Check if there are more pages
        if (response.meta != null) {
          hasMore.value = currentPage.value < response.meta!.lastPage;
        } else {
          hasMore.value = false;
        }

        currentPage.value++;
      } else {
        error.value = response.message;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadNotificationStats() async {
    try {
      final stats = await _notificationService.getNotificationStats();
      notificationStats.value = stats;
    } catch (e) {
      // Silently fail for stats
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _notificationService.markNotificationAsRead(notificationId);
      if (success) {
        // Update the notification in the list
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = notifications[index];
          notifications[index] = Notification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            description: notification.description,
            data: notification.data,
            actionUrl: notification.actionUrl,
            icon: notification.icon,
            isRead: true,
            isClicked: notification.isClicked,
            createdAt: notification.createdAt,
            updatedAt: notification.updatedAt,
          );
        }
        // Update stats
        if (notificationStats.value != null) {
          notificationStats.value = NotificationStats(
            total: notificationStats.value!.total,
            unread: notificationStats.value!.unread - 1,
            unclicked: notificationStats.value!.unclicked,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> markAsClicked(String notificationId) async {
    try {
      final success = await _notificationService.markNotificationAsClicked(notificationId);
      if (success) {
        // Update the notification in the list
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = notifications[index];
          notifications[index] = Notification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            description: notification.description,
            data: notification.data,
            actionUrl: notification.actionUrl,
            icon: notification.icon,
            isRead: notification.isRead,
            isClicked: true,
            createdAt: notification.createdAt,
            updatedAt: notification.updatedAt,
          );
        }
        // Update stats
        if (notificationStats.value != null) {
          notificationStats.value = NotificationStats(
            total: notificationStats.value!.total,
            unread: notificationStats.value!.unread,
            unclicked: notificationStats.value!.unclicked - 1,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllNotificationsAsRead();
      if (success) {
        // Update all notifications in the list
        for (int i = 0; i < notifications.length; i++) {
          final notification = notifications[i];
          if (!notification.isRead) {
            notifications[i] = Notification(
              id: notification.id,
              type: notification.type,
              title: notification.title,
              description: notification.description,
              data: notification.data,
              actionUrl: notification.actionUrl,
              icon: notification.icon,
              isRead: true,
              isClicked: notification.isClicked,
              createdAt: notification.createdAt,
              updatedAt: notification.updatedAt,
            );
          }
        }
        // Update stats
        if (notificationStats.value != null) {
          notificationStats.value = NotificationStats(
            total: notificationStats.value!.total,
            unread: 0,
            unclicked: notificationStats.value!.unclicked,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);
      if (success) {
        // Remove from list
        notifications.removeWhere((n) => n.id == notificationId);
        // Update stats
        if (notificationStats.value != null) {
          final deletedNotification = notifications.firstWhereOrNull((n) => n.id == notificationId);
          notificationStats.value = NotificationStats(
            total: notificationStats.value!.total - 1,
            unread: deletedNotification != null && !deletedNotification.isRead 
                ? notificationStats.value!.unread - 1 
                : notificationStats.value!.unread,
            unclicked: deletedNotification != null && !deletedNotification.isClicked 
                ? notificationStats.value!.unclicked - 1 
                : notificationStats.value!.unclicked,
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void loadMore() {
    if (!isLoadingMore.value && hasMore.value) {
      loadNotifications();
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
    await loadNotificationStats();
  }
}