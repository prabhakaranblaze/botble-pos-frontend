import 'package:martfury/src/model/login_request.dart';
import 'package:martfury/src/model/register_request.dart';
import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/src/service/notification_service.dart';
import 'package:martfury/src/view/screen/main_screen.dart';
import 'package:get/get.dart';

class AuthService extends BaseService {
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final Map<String, Object> requestData = {};
      final loginJson = request.toJson();

      // Convert to Map<String, Object> to satisfy BaseService requirements
      loginJson.forEach((key, value) {
        if (value != null) {
          requestData[key] = value;
        }
      });


      final response = await postAuth('/api/v1/login', requestData);

      // Register device token after successful login
      await NotificationService.registerDeviceToken();
      return response['data'];
    } catch (e) {
      
      // Extract the actual error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      throw Exception(errorMessage);
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await postAuth('/api/v1/password/forgot', {'email': email});
      return response['message'];
    } catch (e) {
      throw Exception('Failed to process forgot password request: $e');
    }
  }

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final Map<String, Object> requestData = {};
      final registerJson = request.toJson();

      // Convert to Map<String, Object> to satisfy BaseService requirements
      registerJson.forEach((key, value) {
        if (value != null) {
          requestData[key] = value;
        }
      });

      final response = await postAuth('/api/v1/register', requestData);

      // Register device token after successful registration
      await NotificationService.registerDeviceToken();
      return response;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> signOut() async {
    
    // Unregister device token before logout
    await NotificationService.unregisterDeviceToken();
    await TokenService.deleteToken();
    
    // IMPORTANT: Don't clear biometric data on logout!
    // We want to keep the biometric settings and token for next login
    // Only clear the main auth token, not biometric settings
    // await BiometricService.clearBiometricData(); // REMOVED THIS
    
    
    Get.offAll(() => const MainScreen());
  }

  Future<Map<String, dynamic>> signInWithApple(
    String identityToken,
  ) async {
    try {
      final response = await postAuth('/api/v1/auth/apple', {
        'identityToken': identityToken,
        'guard': 'customer',
      });

      // Register device token after successful Apple login
      await NotificationService.registerDeviceToken();
      return response['data'];
    } catch (e) {
      throw Exception('Failed to login with Apple: $e');
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle(
    String identityToken,
  ) async {
    try {
      final response = await postAuth('/api/v1/auth/google', {
        'identityToken': identityToken,
        'guard': 'customer',
      });

      // Register device token after successful Google login
      await NotificationService.registerDeviceToken();
      return response['data'];
    } catch (e) {
      throw Exception('Failed to login with Google: $e');
    }
  }

  Future<Map<String, dynamic>> signInWithFacebook(
    String accessToken,
  ) async {
    try {
      final response = await postAuth('/api/v1/auth/facebook', {
        'accessToken': accessToken,
        'guard': 'customer',
      });

      // Register device token after successful Facebook login
      await NotificationService.registerDeviceToken();
      return response['data'];
    } catch (e) {
      throw Exception('Failed to login with Facebook: $e');
    }
  }

  Future<Map<String, dynamic>> signInWithTwitter(
    String accessToken,
    String accessTokenSecret,
  ) async {
    try {
      final response = await postAuth('/api/v1/auth/twitter', {
        'accessToken': accessToken,
        'accessTokenSecret': accessTokenSecret,
        'guard': 'customer',
      });

      // Register device token after successful Twitter login
      await NotificationService.registerDeviceToken();
      return response['data'];
    } catch (e) {
      throw Exception('Failed to login with Twitter: $e');
    }
  }
}
