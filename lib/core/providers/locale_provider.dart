import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'app_locale';

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('fr'), // French
  ];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);

      if (localeCode != null) {
        _locale = Locale(localeCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  /// Change locale and save to SharedPreferences
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      debugPrint('Locale $locale is not supported');
      return;
    }

    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
      debugPrint('Locale saved: ${locale.languageCode}');
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Get display name for a locale
  String getDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return locale.languageCode;
    }
  }

  /// Check if current locale is English
  bool get isEnglish => _locale.languageCode == 'en';

  /// Check if current locale is French
  bool get isFrench => _locale.languageCode == 'fr';

  /// Toggle between English and French
  Future<void> toggleLocale() async {
    if (isEnglish) {
      await setLocale(const Locale('fr'));
    } else {
      await setLocale(const Locale('en'));
    }
  }
}
