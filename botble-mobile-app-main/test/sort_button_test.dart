import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/orders_screen.dart';
import 'package:martfury/src/theme/app_theme.dart';

void main() {
  group('Sort Button Tests', () {
    testWidgets('Sort button has correct dark style colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OrdersScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      // Find the sort button container
      final sortButtonContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(PopupMenuButton<String>),
          matching: find.byType(Container),
        ).first,
      );

      // Verify the container has the correct styling
      final decoration = sortButtonContainer.decoration as BoxDecoration;
      expect(decoration.border, isA<Border>());
      
      final border = decoration.border as Border;
      expect(border.top.color, Colors.black.withValues(alpha: 0.2));

      // Find the sort icon
      final sortIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(PopupMenuButton<String>),
          matching: find.byIcon(Icons.sort),
        ),
      );

      // Verify the icon has black color
      expect(sortIcon.color, Colors.black);
    });

    testWidgets('Sort button works in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const OrdersScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      // Find the sort button and verify it renders without errors
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.byIcon(Icons.sort), findsOneWidget);

      // Tap the sort button to open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify popup menu items are displayed
      expect(find.byType(PopupMenuItem<String>), findsWidgets);
    });
  });
}
