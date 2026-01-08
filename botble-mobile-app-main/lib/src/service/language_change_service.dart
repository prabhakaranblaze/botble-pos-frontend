import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';
import 'package:martfury/src/controller/home_controller.dart';
import 'package:martfury/src/service/language_service.dart';

/// Service to handle language changes and refresh app data
class LanguageChangeService {
  static final StreamController<String> _languageChangeController =
      StreamController<String>.broadcast();
  
  /// Stream that emits when language changes
  static Stream<String> get languageChangeStream => _languageChangeController.stream;
  
  /// Notify all listeners that language has changed
  static void notifyLanguageChanged(String newLanguageLocale) {
    _languageChangeController.add(newLanguageLocale);
  }
  
  /// Refresh all app data after language change
  static Future<void> refreshAppData(BuildContext context, String langLocale, bool isRtl) async {
    try {
      // Update the locale
      final newLocale = Locale(langLocale);
      
      // Try to set the locale, but handle the case where it might not be supported
      try {
        context.setLocale(newLocale);
      } catch (e) {
        // If setting locale fails, we'll still save the language selection
        // The RTL direction will be handled by our custom implementation
        // Silently continue - the language change will still work for RTL
      }
      
      // Update text direction in main app if needed
      await _updateTextDirection();
      
      // Refresh home controller data if it exists
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        await homeController.loadAllData();
        await homeController.loadAds();
      }
      
      // Add small delay to ensure all data is refreshed
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      // If refresh fails, we'll fall back to app restart
      throw Exception('Failed to refresh app data: $e');
    }
  }
  
  /// Update text direction based on selected language
  static Future<void> _updateTextDirection() async {
    try {
      await LanguageService.getTextDirection();
      // The text direction will be applied when the app restarts
      // This is handled in main.dart _MyAppState
    } catch (e) {
      // Silently handle error - text direction will be updated on restart
    }
  }
  
  /// Dispose of resources
  static void dispose() {
    _languageChangeController.close();
  }
}
