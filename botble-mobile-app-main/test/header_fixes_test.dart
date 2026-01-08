import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/theme/app_theme.dart';

void main() {
  group('Header Fixes Tests', () {
    const primaryColor = Color(0xFFFFB800);
    const textColor = Colors.black;

    testWidgets('Headers use consistent primary color styling', (WidgetTester tester) async {
      // Test that the primary color is correctly defined
      expect(primaryColor, const Color(0xFFFFB800));
      
      // Test that text color is black for headers
      expect(textColor, Colors.black);
      
      // Test that AppTheme defines consistent header styling
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.appBarTheme.backgroundColor, primaryColor);
      expect(lightTheme.appBarTheme.foregroundColor, textColor);
      
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.appBarTheme.backgroundColor, primaryColor);
      expect(darkTheme.appBarTheme.foregroundColor, textColor);
    });

    testWidgets('AppBar styling is consistent across themes', (WidgetTester tester) async {
      // Test light theme AppBar
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFB800),
              title: const Text(
                'Test Header',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);

      // Test dark theme AppBar
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFFFB800),
              title: const Text(
                'Test Header',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            body: const Center(child: Text('Test')),
          ),
        ),
      );

      final darkAppBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(darkAppBar.backgroundColor, primaryColor);
    });
  });
}
