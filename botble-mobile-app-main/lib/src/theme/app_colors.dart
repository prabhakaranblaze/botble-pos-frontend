import 'package:flutter/material.dart';

/// App color constants that adapt to light and dark themes
class AppColors {
  // Primary brand color (consistent across themes)
  static const Color primary = Color(0xFFFFB800);
  static const Color primaryDark = Color(0xFFE6A600);

  // Background colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121212);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color darkCardBackground = Color(0xFF2C2C2C);

  // Text colors
  static const Color lightPrimaryText = Color(0xFF212121);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);

  static const Color lightSecondaryText = Color(0xFF757575);
  static const Color darkSecondaryText = Color(0xFFB3B3B3);

  static const Color lightHintText = Color(0xFF9E9E9E);
  static const Color darkHintText = Color(0xFF666666);

  // Border colors
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color darkBorder = Color(0xFF404040);

  // Skeleton loading colors
  static const Color lightSkeleton = Color(0xFFE0E0E0);
  static const Color darkSkeleton = Color(0xFF404040);

  // Status colors (consistent across themes)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Price colors
  static const Color priceColor = Color(0xFFE1332D);
  static const Color originalPriceColor = Color(0xFF9E9E9E);

  /// Get background color based on current theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  /// Get surface color based on current theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  /// Get card background color based on current theme
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardBackground
        : lightCardBackground;
  }

  /// Get primary text color based on current theme
  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimaryText
        : lightPrimaryText;
  }

  /// Get secondary text color based on current theme
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondaryText
        : lightSecondaryText;
  }

  /// Get hint text color based on current theme
  static Color getHintTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkHintText
        : lightHintText;
  }

  /// Get border color based on current theme
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  /// Get skeleton loading color based on current theme
  static Color getSkeletonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSkeleton
        : lightSkeleton;
  }
}
