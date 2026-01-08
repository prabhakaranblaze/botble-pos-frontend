import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTokenKey = 'biometric_token';
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }
  
  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;
      
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;
      
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }
  
  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }
  
  // Check if Face ID is available (iOS only)
  Future<bool> isFaceIdAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } on PlatformException {
      return false;
    }
  }
  
  // Check if Touch ID is available (iOS only)
  Future<bool> isTouchIdAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint);
    } on PlatformException {
      return false;
    }
  }
  
  // Authenticate with biometrics
  Future<bool> authenticate({String reason = 'Please authenticate to continue'}) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } on PlatformException {
      // Biometric authentication failed or was cancelled
      return false;
    }
  }
  
  // Check if biometric login is enabled
  static Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
  
  // Enable/disable biometric login
  static Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
  
  // Store token for biometric login
  static Future<void> setBiometricToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_biometricTokenKey, token);
    } else {
      await prefs.remove(_biometricTokenKey);
    }
  }
  
  // Get stored token for biometric login
  static Future<String?> getBiometricToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricTokenKey);
  }
  
  // Clear biometric data (on logout)
  static Future<void> clearBiometricData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_biometricTokenKey);
  }
  
  // Stop authentication
  Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }
}