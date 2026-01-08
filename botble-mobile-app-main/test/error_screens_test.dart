import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/server_error_screen.dart';
import 'package:martfury/src/view/screen/not_found_error_screen.dart';
import 'package:martfury/src/theme/app_colors.dart';

void main() {
  group('Error Screens Tests', () {
    group('ServerErrorScreen Tests', () {
      testWidgets('ServerErrorScreen displays correctly', (WidgetTester tester) async {
        bool retryPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: ServerErrorScreen(
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Check if server error icon is displayed
        expect(find.byIcon(Icons.dns_outlined), findsOneWidget);

        // Check if retry button is displayed (look for refresh icon)
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        // Test retry button functionality by tapping the button with refresh icon
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(retryPressed, isTrue);
      });

      testWidgets('ServerErrorScreen without retry callback', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ServerErrorScreen(),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Check if server error icon is displayed
        expect(find.byIcon(Icons.dns_outlined), findsOneWidget);

        // Check if retry button is NOT displayed when no callback is provided
        expect(find.byIcon(Icons.refresh), findsNothing);
      });

      testWidgets('ServerErrorScreen uses correct colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const ServerErrorScreen(),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Find the icon widget
        final iconFinder = find.byIcon(Icons.dns_outlined);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, equals(AppColors.error));
      });

      testWidgets('ServerErrorScreen adapts to dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const ServerErrorScreen(),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Check if the screen renders without errors in dark mode
        expect(find.byType(ServerErrorScreen), findsOneWidget);
        expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
      });
    });

    group('NotFoundErrorScreen Tests', () {
      testWidgets('NotFoundErrorScreen displays correctly', (WidgetTester tester) async {
        bool retryPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: NotFoundErrorScreen(
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Check if not found icon is displayed
        expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);

        // Check if go back button is displayed (look for arrow back icon)
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Test go back button functionality by tapping the button with arrow back icon
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump();

        expect(retryPressed, isTrue);
      });

      testWidgets('NotFoundErrorScreen without retry callback', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NotFoundErrorScreen(),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Check if not found icon is displayed
        expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);

        // Check if go back button is NOT displayed when no callback is provided
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });

      testWidgets('NotFoundErrorScreen uses correct colors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const NotFoundErrorScreen(),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Find the icon widget
        final iconFinder = find.byIcon(Icons.search_off_outlined);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, equals(AppColors.info));
      });

      testWidgets('NotFoundErrorScreen adapts to dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const NotFoundErrorScreen(),
          ),
        );

        // Wait for the widget to build
        await tester.pumpAndSettle();

        // Check if the screen renders without errors in dark mode
        expect(find.byType(NotFoundErrorScreen), findsOneWidget);
        expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      });
    });
  });
}
