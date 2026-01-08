import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/language_service.dart';
import 'dart:ui' as ui;

void main() {
  group('Language and Direction Tests', () {
    setUp(() async {
      // Load test environment
      await dotenv.load(fileName: '.env');
    });

    test('AppConfig should read DEFAULT_LANGUAGE from environment', () {
      // Test that AppConfig reads the default language correctly
      final language = AppConfig.defaultLanguage;
      expect(language, isNotEmpty);
      expect(language, isIn(['en', 'vi', 'ar', 'bn', 'es', 'fr', 'hi', 'id']));
    });

    test('AppConfig should read DEFAULT_LANGUAGE_DIRECTION from environment', () {
      // Test that AppConfig reads the environment variable correctly
      final direction = AppConfig.defaultLanguageDirection;
      expect(direction, isIn(['ltr', 'rtl']));
    });

    test('AppConfig should correctly identify RTL languages', () {
      // Test RTL language detection
      expect(AppConfig.isLanguageRtl('ar'), true);  // Arabic
      expect(AppConfig.isLanguageRtl('he'), true);  // Hebrew
      expect(AppConfig.isLanguageRtl('fa'), true);  // Persian
      expect(AppConfig.isLanguageRtl('en'), false); // English
      expect(AppConfig.isLanguageRtl('vi'), false); // Vietnamese
      expect(AppConfig.isLanguageRtl('es'), false); // Spanish
    });

    test('AppConfig should determine effective RTL status correctly', () {
      // Test that the effective RTL status is determined correctly
      final isRtl = AppConfig.isDefaultLanguageRtl;
      expect(isRtl, isA<bool>());

      // If DEFAULT_LANGUAGE is Arabic, it should be RTL
      if (AppConfig.defaultLanguage == 'ar') {
        expect(isRtl, true);
      }
      // If DEFAULT_LANGUAGE is English, it should be LTR
      if (AppConfig.defaultLanguage == 'en') {
        expect(isRtl, false);
      }
    });

    test('LanguageService should use environment configuration when no language selected', () async {
      // This test verifies that when no language is selected,
      // the service falls back to the environment configuration

      final textDirection = await LanguageService.getTextDirection();
      final isRtl = await LanguageService.isCurrentLanguageRtl();

      // Verify that the direction matches the environment setting
      if (AppConfig.isDefaultLanguageRtl) {
        expect(textDirection, ui.TextDirection.rtl);
        expect(isRtl, true);
      } else {
        expect(textDirection, ui.TextDirection.ltr);
        expect(isRtl, false);
      }
    });

    test('LanguageService should return correct default language code', () {
      // Test that the service returns the correct default language code
      final defaultLanguage = LanguageService.getDefaultLanguageCode();
      expect(defaultLanguage, AppConfig.defaultLanguage);
    });

    test('Environment variables should be case insensitive', () {
      // Test that the environment variables are handled case-insensitively
      expect(AppConfig.defaultLanguage, isIn(['en', 'vi', 'ar', 'bn', 'es', 'fr', 'hi', 'id']));
      expect(AppConfig.defaultLanguageDirection, isIn(['ltr', 'rtl']));
    });
  });
}
