import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:martfury/src/service/base_service.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/token_service.dart';

class ProfileService extends BaseService {
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get('/api/v1/me');

      return response['data'];
    } catch (e) {
      
      // Provide more specific error messages
      if (e.toString().contains('SocketException') || 
          e.toString().contains('ClientException')) {
        throw Exception('No internet connection. Please check your network.');
      } else if (e.toString().contains('Unauthorized')) {
        throw Exception('Session expired. Please sign in again.');
      } else if (e.toString().contains('Server Error')) {
        throw Exception('Server error. Please try again later.');
      } else if (e.toString().contains('Not Found')) {
        throw Exception('Profile not found. Please contact support.');
      }
      
      throw Exception('Failed to load profile. Please try again.');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? dob,
  }) async {
    try {
      final response = await put('/api/v1/me', {
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (dob != null) 'dob': dob,
      });

      return response['data'];
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> updateAvatar(File avatarFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/api/v1/update/avatar'),
      );

      // Add authorization header
      final token = await TokenService.getToken();
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to update avatar');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    bool? biometricEnabled,
  }) async {
    try {
      final response = await put('/api/v1/settings', {
        if (biometricEnabled != null) 'biometric_enabled': biometricEnabled,
      });

      return response['data'];
    } catch (e) {
      // If the endpoint doesn't exist yet (404), don't throw error
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        return {
          'message': 'Settings saved locally',
          'settings': {
            'biometric_enabled': biometricEnabled
          }
        };
      }
      throw Exception('Failed to update settings: $e');
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await put('/api/v1/update/password', {
        'old_password': currentPassword,
        'password': newPassword,
      });

      return response;
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
}
