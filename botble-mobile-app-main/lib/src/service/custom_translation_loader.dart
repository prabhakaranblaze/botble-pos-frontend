import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' show AssetLoader;

/// Custom translation loader that prioritizes user translations in assets/translations
/// over default translations in lib/translations
class CustomTranslationLoader extends AssetLoader {
  const CustomTranslationLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final String languageCode = locale.languageCode;
    final String fileName = '$languageCode.json';

    // First, try to load user translations from assets/translations
    Map<String, dynamic>? userTranslations = await _loadTranslationsFromPath(
      'assets/translations/$fileName',
    );

    // Then, load default translations from lib/translations
    Map<String, dynamic>? defaultTranslations = await _loadTranslationsFromPath(
      'lib/translations/$fileName',
    );

    // If no default translations found, return user translations (or null)
    if (defaultTranslations == null) {
      return userTranslations;
    }

    // If no user translations found, return default translations
    if (userTranslations == null) {
      return defaultTranslations;
    }

    // Merge translations: user translations override default translations

    return _mergeTranslations(defaultTranslations, userTranslations);
  }

  /// Load translations from a specific asset path
  Future<Map<String, dynamic>?> _loadTranslationsFromPath(
    String assetPath,
  ) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> result =
          json.decode(jsonString) as Map<String, dynamic>;

      return result;
    } catch (e) {
      // File doesn't exist or can't be loaded
      return null;
    }
  }

  /// Merge two translation maps, with override taking precedence over base
  Map<String, dynamic> _mergeTranslations(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(base);

    override.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          result[key] is Map<String, dynamic>) {
        // Recursively merge nested objects
        result[key] = _mergeTranslations(
          result[key] as Map<String, dynamic>,
          value,
        );
      } else {
        // Override the value
        result[key] = value;
      }
    });

    return result;
  }
}
