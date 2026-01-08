import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';

void main() {
  group('Review Image Upload Tests', () {
    testWidgets('Image upload section should be visible in review form', (WidgetTester tester) async {
      // Mock product data
      final mockProduct = {
        'slug': 'test-product',
        'title': 'Test Product',
        'imageUrl': 'https://example.com/image.jpg',
        'price': 99.99,
        'reviews': 5,
        'rating': 4.5,
      };

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailScreen(product: mockProduct),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the upload photos text is present
      // Note: This test may need to be adjusted based on the actual widget structure
      // and whether the user is logged in and hasn't reviewed yet
      expect(find.text('Upload photos'), findsOneWidget);
    });

    testWidgets('Image upload info text should be displayed', (WidgetTester tester) async {
      final mockProduct = {
        'slug': 'test-product',
        'title': 'Test Product',
        'imageUrl': 'https://example.com/image.jpg',
        'price': 99.99,
        'reviews': 5,
        'rating': 4.5,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailScreen(product: mockProduct),
        ),
      );

      await tester.pumpAndSettle();

      // Look for the info text about photo upload limits
      expect(find.textContaining('6 photos'), findsOneWidget);
      expect(find.textContaining('2 MB'), findsOneWidget);
    });
  });
}
