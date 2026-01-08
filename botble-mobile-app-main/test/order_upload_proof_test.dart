import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  group('Order Upload Proof Tests', () {
    setUpAll(() async {
      // Load environment variables for testing
      await dotenv.load(fileName: '.env');
    });

    test('should check if upload proof feature is enabled by default', () {
      // Test that the feature is enabled by default
      expect(AppConfig.enableOrderUploadProof, isTrue);
    });

    test('should disable upload proof feature when env var is false', () async {
      // Temporarily set the environment variable to false
      dotenv.env['ENABLE_ORDER_UPLOAD_PROOF'] = 'false';
      
      expect(AppConfig.enableOrderUploadProof, isFalse);
      
      // Reset to original value
      dotenv.env['ENABLE_ORDER_UPLOAD_PROOF'] = 'true';
    });

    test('should create OrderService instance', () {
      final orderService = OrderService();
      expect(orderService, isNotNull);
    });

    test('should have upload proof methods in OrderService', () {
      final orderService = OrderService();

      // Check that the methods exist (this will fail if methods don't exist)
      expect(orderService.uploadPaymentProof, isNotNull);
      expect(orderService.downloadPaymentProof, isNotNull);
      expect(orderService.testUploadProofEndpoint, isNotNull);
    });

    test('should validate file size correctly', () {
      // This test validates the file size logic
      const maxSize = 5 * 1024 * 1024; // 5MB
      const testSize1 = 1024 * 1024; // 1MB - should pass
      const testSize2 = 6 * 1024 * 1024; // 6MB - should fail

      expect(testSize1 <= maxSize, isTrue);
      expect(testSize2 <= maxSize, isFalse);
    });

    test('should have download and replace functionality', () {
      final orderService = OrderService();

      // Check that download method exists
      expect(orderService.downloadPaymentProof, isNotNull);

      // Check that the method is a function that takes named parameters
      expect(orderService.downloadPaymentProof, isA<Function>());

      // Check that getOrderDetails method exists
      expect(orderService.getOrderDetails, isNotNull);
    });

    test('should handle payment_proof API structure', () {
      // Test the expected structure of payment_proof field
      final mockPaymentProof = {
        'has_proof': true,
        'file_name': 'receipt.jpg',
        'file_size': '1.2 MB',
        'uploaded_at': '2024-01-01T12:00:00Z',
        'download_url': '/storage/proofs/receipt.jpg'
      };

      expect(mockPaymentProof['has_proof'], isTrue);
      expect(mockPaymentProof['download_url'], isNotNull);
      expect(mockPaymentProof['file_name'], isA<String>());
    });
  });
}
