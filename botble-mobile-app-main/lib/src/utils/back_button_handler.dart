import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/view/screen/main_screen.dart';

/// Utility class to handle back button behavior consistently across the app
class BackButtonHandler {
  /// Handle back button for screens that should navigate to main screen
  /// instead of closing the app
  static Future<bool> handleBackToMain(BuildContext context) async {
    // Check if we can pop the current route
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    } else {
      // If we can't pop, navigate to main screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(initialIndex: 0),
        ),
        (route) => false,
      );
      return false;
    }
  }

  /// Handle back button for screens that should go to a specific main screen tab
  static Future<bool> handleBackToMainTab(BuildContext context, int tabIndex) async {
    // Check if we can pop the current route
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    } else {
      // If we can't pop, navigate to main screen with specific tab
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(initialIndex: tabIndex),
        ),
        (route) => false,
      );
      return false;
    }
  }

  /// Handle back button for modal screens (like cart, profile settings)
  /// These should just pop or go back to previous screen
  static Future<bool> handleModalBack(BuildContext context) async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    } else {
      // If somehow we can't pop, go to main screen
      return handleBackToMain(context);
    }
  }

  /// Handle back button with double-tap to exit functionality
  /// Used in main screen and other root screens
  static Future<bool> handleDoubleBackToExit(
    BuildContext context, 
    DateTime? lastBackPressed,
    Function(DateTime) updateLastBackPressed,
  ) async {
    final now = DateTime.now();
    if (lastBackPressed == null || 
        now.difference(lastBackPressed) > const Duration(seconds: 2)) {
      updateLastBackPressed(now);
      
      // Show a snackbar to inform user about double-tap to exit
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.press_back_again_to_exit'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false; // Don't exit the app
    }

    // Double-tap detected, exit the app
    SystemNavigator.pop();
    return true;
  }

  /// Create a PopScope widget with proper back button handling
  static Widget createPopScope({
    required Widget child,
    required Future<bool> Function() onWillPop,
  }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await onWillPop();
        }
      },
      child: child,
    );
  }

  /// Create a PopScope widget that navigates to main screen
  static Widget createMainScreenPopScope({
    required Widget child,
    required BuildContext context,
    int tabIndex = 0,
  }) {
    return createPopScope(
      child: child,
      onWillPop: () => handleBackToMainTab(context, tabIndex),
    );
  }

  /// Create a PopScope widget for modal screens
  static Widget createModalPopScope({
    required Widget child,
    required BuildContext context,
  }) {
    return createPopScope(
      child: child,
      onWillPop: () => handleModalBack(context),
    );
  }
}
