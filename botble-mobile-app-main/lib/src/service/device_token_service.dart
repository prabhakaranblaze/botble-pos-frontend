import 'package:martfury/src/model/device_token.dart';
import 'package:martfury/src/service/base_service.dart';

class DeviceTokenService extends BaseService {
  /// Register device token with the API
  Future<Map<String, dynamic>> registerDeviceToken(
    DeviceToken deviceToken,
  ) async {
    try {
      final Map<String, Object> requestData = {};
      final tokenJson = deviceToken.toJson();

      // Convert to Map<String, Object> to satisfy BaseService requirements
      tokenJson.forEach((key, value) {
        if (value != null) {
          requestData[key] = value;
        }
      });

      final response = await post('/api/v1/device-tokens', requestData);

      return response;
    } catch (e) {
      throw Exception('Failed to register device token: $e');
    }
  }

  /// Unregister device token from the API
  Future<Map<String, dynamic>> unregisterDeviceToken(String token) async {
    try {
      final response = await delete('/api/v1/device-tokens/by-token', {
        'token': token,
      });

      return response;
    } catch (e) {
      throw Exception('Failed to unregister device token: $e');
    }
  }

  /// Update device token with new user information
  Future<Map<String, dynamic>> updateDeviceToken(
    DeviceToken deviceToken,
  ) async {
    try {
      final Map<String, Object> requestData = {};
      final tokenJson = deviceToken.toJson();

      // Convert to Map<String, Object> to satisfy BaseService requirements
      tokenJson.forEach((key, value) {
        if (value != null) {
          requestData[key] = value;
        }
      });

      final response = await put('/api/v1/device-tokens', requestData);

      return response;
    } catch (e) {
      throw Exception('Failed to update device token: $e');
    }
  }

  /// Get all device tokens for the current user
  Future<List<DeviceToken>> getUserDeviceTokens() async {
    try {
      final response = await get('/api/v1/device-tokens');

      final List<dynamic> tokensJson = response['data'] ?? [];
      return tokensJson.map((json) => DeviceToken.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user device tokens: $e');
    }
  }
}
