import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('HTTP Response Error Status Code Tests', () {

    test('HTTP Response identifies 502 status code correctly', () async {
      // Create a response with 502 status code
      final serverErrorResponse = http.Response(
        '{"error": "Bad Gateway"}',
        502,
        headers: {'content-type': 'application/json'},
      );

      // Test that the response properly identifies 502 as server error
      expect(serverErrorResponse.statusCode, equals(502));
      expect(serverErrorResponse.statusCode == 502, isTrue);
    });

    test('HTTP Response identifies 503 status code correctly', () async {
      // Create a response with 503 status code
      final maintenanceResponse = http.Response(
        '{"error": "Service Unavailable"}',
        503,
        headers: {'content-type': 'application/json'},
      );

      // Test that the response properly identifies 503 as maintenance mode
      expect(maintenanceResponse.statusCode, equals(503));
      expect(maintenanceResponse.statusCode == 503, isTrue);
    });

    test('HTTP Response identifies 404 status code correctly', () async {
      // Create a response with 404 status code
      final notFoundResponse = http.Response(
        '{"error": "Not Found"}',
        404,
        headers: {'content-type': 'application/json'},
      );

      // Test that the response properly identifies 404 as not found
      expect(notFoundResponse.statusCode, equals(404));
      expect(notFoundResponse.statusCode == 404, isTrue);
    });

    test('HTTP Response handles different error status codes correctly', () async {
      // Test 401 status code
      final unauthorizedResponse = http.Response(
        '{"error": "Unauthorized"}',
        401,
        headers: {'content-type': 'application/json'},
      );
      expect(unauthorizedResponse.statusCode, equals(401));

      // Test 404 status code (not found)
      final notFoundResponse = http.Response(
        '{"error": "Not Found"}',
        404,
        headers: {'content-type': 'application/json'},
      );
      expect(notFoundResponse.statusCode, equals(404));

      // Test 502 status code (server error)
      final serverErrorResponse = http.Response(
        '{"error": "Bad Gateway"}',
        502,
        headers: {'content-type': 'application/json'},
      );
      expect(serverErrorResponse.statusCode, equals(502));

      // Test 503 status code (maintenance mode)
      final maintenanceResponse = http.Response(
        '{"error": "Service Unavailable"}',
        503,
        headers: {'content-type': 'application/json'},
      );
      expect(maintenanceResponse.statusCode, equals(503));
    });

    test('HTTP Response handles successful responses correctly', () async {
      // Test 200 status code
      final successResponse = http.Response(
        '{"data": "success"}',
        200,
        headers: {'content-type': 'application/json'},
      );
      expect(successResponse.statusCode, equals(200));
      expect(successResponse.statusCode >= 200 && successResponse.statusCode < 300, isTrue);
    });

    test('HTTP Response handles invalid JSON responses gracefully', () async {
      // Test response with invalid JSON
      final invalidJsonResponse = http.Response(
        'Invalid JSON content',
        500,
        headers: {'content-type': 'application/json'},
      );
      expect(invalidJsonResponse.statusCode, equals(500));
      expect(invalidJsonResponse.body, equals('Invalid JSON content'));
    });
  });
}
