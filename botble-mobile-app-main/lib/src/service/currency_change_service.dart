import 'dart:async';
import 'package:get/get.dart';
import 'package:martfury/src/controller/home_controller.dart';

/// Service to handle currency changes and refresh app data
class CurrencyChangeService {
  static final StreamController<String> _currencyChangeController =
      StreamController<String>.broadcast();
  
  /// Stream that emits when currency changes
  static Stream<String> get currencyChangeStream => _currencyChangeController.stream;
  
  /// Notify all listeners that currency has changed
  static void notifyCurrencyChanged(String newCurrencyTitle) {
    _currencyChangeController.add(newCurrencyTitle);
  }
  
  /// Refresh all app data after currency change
  static Future<void> refreshAppData() async {
    try {
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
  
  /// Dispose of resources
  static void dispose() {
    _currencyChangeController.close();
  }
}
