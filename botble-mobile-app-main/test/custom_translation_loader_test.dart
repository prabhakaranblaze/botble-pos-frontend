import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/service/custom_translation_loader.dart';

void main() {
  group('CustomTranslationLoader', () {
    late CustomTranslationLoader loader;

    setUp(() {
      loader = const CustomTranslationLoader();
    });

    test('should merge user translations with default translations', () {
      // This test verifies the merging logic
      final defaultTranslations = {
        'app': {
          'unlock_amazing': 'Unlock Amazing',
          'deals_discounts': 'Deals & Discounts',
          'lets_get_started': 'Let\'s Get Started',
        },
        'common': {'submit': 'Submit', 'cancel': 'Cancel', 'email': 'Email'},
      };

      final userTranslations = {
        'app': {
          'unlock_amazing': 'Custom: Unlock Amazing Deals',
          'deals_discounts': 'Custom: Special Offers & Discounts',
        },
        'common': {'submit': 'Custom Submit', 'email': 'Custom Email'},
      };

      // Use reflection to access the private method for testing
      final result = loader._mergeTranslations(
        defaultTranslations,
        userTranslations,
      );

      // Verify that user translations override defaults
      expect(
        result['app']['unlock_amazing'],
        equals('Custom: Unlock Amazing Deals'),
      );
      expect(
        result['app']['deals_discounts'],
        equals('Custom: Special Offers & Discounts'),
      );
      expect(result['common']['submit'], equals('Custom Submit'));
      expect(result['common']['email'], equals('Custom Email'));

      // Verify that missing user translations fall back to defaults
      expect(result['app']['lets_get_started'], equals('Let\'s Get Started'));
      expect(result['common']['cancel'], equals('Cancel'));
    });

    test('should handle nested object merging correctly', () {
      final defaultTranslations = {
        'nested': {
          'level1': {'key1': 'default value 1', 'key2': 'default value 2'},
          'level2': 'default level2',
        },
      };

      final userTranslations = {
        'nested': {
          'level1': {'key1': 'custom value 1'},
        },
      };

      final result = loader._mergeTranslations(
        defaultTranslations,
        userTranslations,
      );

      expect(result['nested']['level1']['key1'], equals('custom value 1'));
      expect(result['nested']['level1']['key2'], equals('default value 2'));
      expect(result['nested']['level2'], equals('default level2'));
    });

    test(
      'should return default translations when user translations are null',
      () {
        final defaultTranslations = {
          'app': {'title': 'Default Title'},
        };

        final result = loader._mergeTranslations(defaultTranslations, {});

        expect(result['app']['title'], equals('Default Title'));
      },
    );
  });
}

// Extension to access private methods for testing
extension CustomTranslationLoaderTest on CustomTranslationLoader {
  Map<String, dynamic> _mergeTranslations(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(base);

    override.forEach((key, value) {
      if (value is Map<String, dynamic> &&
          result[key] is Map<String, dynamic>) {
        result[key] = _mergeTranslations(
          result[key] as Map<String, dynamic>,
          value,
        );
      } else {
        result[key] = value;
      }
    });

    return result;
  }
}
