import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/maintenance_screen.dart';
import 'package:martfury/src/theme/app_colors.dart';

// Mock EasyLocalization for testing
class MockEasyLocalization extends StatelessWidget {
  final Widget child;

  const MockEasyLocalization({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

void main() {
  group('Maintenance Screen Tests', () {
    testWidgets('MaintenanceScreen displays correctly', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MaintenanceScreen(
            onRetry: () {
              retryPressed = true;
            },
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if maintenance icon is displayed
      expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);

      // Check if retry button is displayed (look for any button with refresh icon)
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test retry button functionality by tapping the button with refresh icon
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('MaintenanceScreen without retry callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MaintenanceScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if maintenance icon is displayed
      expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);

      // Check if retry button is NOT displayed when no callback is provided
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('MaintenanceScreen uses correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const MaintenanceScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find the icon widget
      final iconFinder = find.byIcon(Icons.build_circle_outlined);
      expect(iconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.color, equals(AppColors.warning));
    });

    testWidgets('MaintenanceScreen adapts to dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const MaintenanceScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if the screen renders without errors in dark mode
      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    });
  });
}
