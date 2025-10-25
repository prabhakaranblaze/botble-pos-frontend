import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/constants/app_constants.dart';
import '../models/user.dart';
import '../models/session.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Add to StorageService class
  Future<void> saveDeviceName(String deviceName) async {
    await _prefs?.setString('device_name', deviceName);
  }

  Future<String> getDeviceName() async {
    return _prefs?.getString('device_name') ?? 'Desktop Terminal';
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConstants.keyToken, token);
  }

  Future<String?> getToken() async {
    return _prefs?.getString(AppConstants.keyToken);
  }

  Future<void> removeToken() async {
    await _prefs?.remove(AppConstants.keyToken);
  }

  // User management
  Future<void> saveUser(User user) async {
    await _prefs?.setString(AppConstants.keyUser, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final userJson = _prefs?.getString(AppConstants.keyUser);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<void> removeUser() async {
    await _prefs?.remove(AppConstants.keyUser);
  }

  // Session management
  Future<void> saveActiveSession(PosSession session) async {
    await _prefs?.setString(
      AppConstants.keyActiveSession,
      jsonEncode(session.toJson()),
    );
  }

  Future<PosSession?> getActiveSession() async {
    final sessionJson = _prefs?.getString(AppConstants.keyActiveSession);
    if (sessionJson == null) return null;
    return PosSession.fromJson(jsonDecode(sessionJson));
  }

  Future<void> removeActiveSession() async {
    await _prefs?.remove(AppConstants.keyActiveSession);
  }

  // Online status
  Future<void> setOnlineStatus(bool isOnline) async {
    await _prefs?.setBool(AppConstants.keyIsOnline, isOnline);
  }

  Future<bool> getOnlineStatus() async {
    return _prefs?.getBool(AppConstants.keyIsOnline) ?? true;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
