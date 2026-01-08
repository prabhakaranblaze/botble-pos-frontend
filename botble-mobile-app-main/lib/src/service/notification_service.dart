import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:martfury/src/model/device_token.dart';
import 'package:martfury/src/service/device_token_service.dart';
import 'package:martfury/src/service/profile_service.dart';
import 'package:martfury/src/service/token_service.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final DeviceTokenService _deviceTokenService = DeviceTokenService();
  static final ProfileService _profileService = ProfileService();
  static String? _deviceToken;

  /// Initialize FCM Push Notifications
  static Future<void> initialize() async {
    try {
      // Initialize local notifications (always available)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Check if Firebase is available before initializing FCM
      if (!_isFirebaseAvailable()) {
        return;
      }

      // Request FCM permissions
      final messaging = FirebaseMessaging.instance;

      // Request permission for iOS and configure APNS
      if (Platform.isIOS) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: false,
          announcement: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.denied) {}

        // Set APNS token for iOS (helps with FCM token generation)
        try {
          await messaging.setAutoInitEnabled(true);

          // Force APNS token registration
          await messaging.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e) {
          // iOS permission request failed - notifications may not work properly
          debugPrint('iOS notification permission request failed: $e');
        }
      } else {
        // Android permissions
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Set up FCM message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Listen for token refresh
      messaging.onTokenRefresh.listen((token) {
        _deviceToken = token;
        _sendTokenToServer(token);
      });

      // Get and register initial token
      await registerDeviceToken();
    } catch (e) {
      // Notification service initialization failed - notifications may not work
      debugPrint('Notification service initialization failed: $e');
    }
  }

  /// Check if Firebase is available and initialized
  static bool _isFirebaseAvailable() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get FCM token and register with API
  static Future<void> registerDeviceToken() async {
    try {
      String? token = await _getFCMToken();
      if (token != null) {
        _deviceToken = token;
        await _sendTokenToServer(token);
      } else {
        // Generate a fallback token for development/testing
        final fallbackToken = await _generateFallbackToken();
        if (fallbackToken != null) {
          _deviceToken = fallbackToken;
          await _sendTokenToServer(fallbackToken);
        }
      }
    } catch (e) {
      // Device token registration failed - notifications may not work properly
      debugPrint('Device token registration failed: $e');
    }
  }

  /// Generate a fallback token for development when FCM is not available
  static Future<String?> _generateFallbackToken() async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final fallbackToken =
          'dev_${platform}_${deviceInfo['deviceId']}_${packageInfo.version}';

      return fallbackToken;
    } catch (e) {
      return null;
    }
  }

  /// Get FCM token from Firebase
  static Future<String?> _getFCMToken() async {
    try {
      if (!_isFirebaseAvailable()) {
        return null;
      }

      final messaging = FirebaseMessaging.instance;

      // For iOS, ensure APNS token is available first
      if (Platform.isIOS) {
        try {
          // Wait for APNS token to be available
          final apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            // Wait longer for physical devices
            await Future.delayed(const Duration(seconds: 5));
            final retryApnsToken = await messaging.getAPNSToken();
            if (retryApnsToken == null) {
              // For physical devices, this is a real problem
              return null;
            } else {}
          } else {}
        } catch (apnsError) {
          return null;
        }
      }

      // Get FCM token with timeout

      final String? token = await messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return null;
        },
      );

      return token;
    } catch (e) {
      return null;
    }
  }

  /// Send device token to server
  static Future<void> _sendTokenToServer(String token) async {
    try {
      // Get device information
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      // Get user information if logged in
      int? userId;
      String userType = 'guest';

      try {
        final authToken = await TokenService.getToken();
        if (authToken != null && authToken.isNotEmpty) {
          final userProfile = await _profileService.getProfile();
          userId = userProfile['id'];
          userType = 'customer';
        } else {}
      } catch (e) {
        // User not logged in, continue as guest
      }

      // Create device token object
      final deviceToken = DeviceToken(
        token: token,
        platform: Platform.isAndroid ? 'android' : 'ios',
        appVersion: packageInfo.version,
        deviceId: deviceInfo['deviceId'],
        userType: userType,
        userId: userId,
      );

      // Send to API
      await _deviceTokenService.registerDeviceToken(deviceToken);
    } catch (e) {
      // Failed to send token to server - notifications may not work properly
      debugPrint('Failed to send device token to server: $e');
    }
  }

  /// Get device information
  static Future<Map<String, String?>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return {
        'deviceId': androidInfo.id,
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
      };
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return {
        'deviceId': iosInfo.identifierForVendor,
        'model': iosInfo.model,
        'manufacturer': 'Apple',
      };
    }

    return {'deviceId': null, 'model': null, 'manufacturer': null};
  }

  /// Handle FCM messages when app is in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Handle FCM messages when app is opened from notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    // Handle navigation based on message data
    _handleNotificationNavigation(message.data);
  }

  /// Show local notification from FCM message
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification navigation
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Add your navigation logic here based on the data
  }

  /// Handle notification tap
  static void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        // Failed to parse notification payload - ignoring notification
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// Unregister device token (call on logout)
  static Future<void> unregisterDeviceToken() async {
    try {
      if (_deviceToken != null) {
        await _deviceTokenService.unregisterDeviceToken(_deviceToken!);
        _deviceToken = null;
      }
    } catch (e) {
      // Continue execution even if unregister fails
    }
  }
}
