import 'package:flutter/foundation.dart';
import '../../core/models/user.dart';
import '../../core/api/api_service.dart';
import '../../core/services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService, this._storageService) {
    _checkAuthentication();
  }

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkAuthentication() async {
    final token = await _storageService.getToken();
    final user = await _storageService.getUser();

    if (token != null && user != null) {
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(
      String username, String password, String deviceName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse =
          await _apiService.login(username, password, deviceName);

      await _storageService.saveToken(authResponse.token);
      await _storageService.saveUser(authResponse.user);

      _user = authResponse.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('🔴 LOGOUT: Starting logout process');

    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('⚠️ LOGOUT: API logout failed (continuing anyway): $e');
    }

    // Clear all local data
    await _storageService.clearAll();

    _user = null;
    _isAuthenticated = false;

    debugPrint('✅ LOGOUT: Logout complete, notifying listeners');
    notifyListeners();
  }

  /// Verify password for lock screen unlock
  Future<bool> verifyPassword(String password) async {
    try {
      return await _apiService.verifyPassword(password);
    } catch (e) {
      debugPrint('❌ AUTH: Verify password failed: $e');
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
