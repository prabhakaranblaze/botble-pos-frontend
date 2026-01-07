import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/config/env_config.dart';

class AppConstants {
  // API Configuration - now uses environment config
  static String get baseUrl => EnvConfig.baseUrl;
  static String get apiKey => EnvConfig.apiKey;

  // App Configuration
  static const String appName = 'StampSmart POS';
// Dynamic device name based on computer name
  static String get deviceName {
    try {
      return Platform.localHostname.isNotEmpty
          ? 'POS-${Platform.localHostname}'
          : 'Desktop Terminal';
    } catch (e) {
      return 'Desktop Terminal';
    }
  }

  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'user_data';
  static const String keyStoreId = 'store_id';
  static const String keyActiveSession = 'active_session';
  static const String keyIsOnline = 'is_online';

  // Database
  static const String dbName = 'pos_local.db';
  static const int dbVersion = 1;

  // Pagination
  static const int itemsPerPage = 20;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 5);
}

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
}
