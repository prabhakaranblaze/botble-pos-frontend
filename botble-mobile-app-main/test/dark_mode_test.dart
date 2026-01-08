import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/tracking_order_screen.dart';
import 'package:martfury/src/view/screen/reviews_screen.dart';
import 'package:martfury/src/theme/app_theme.dart';
import 'package:martfury/src/theme/app_colors.dart';

void main() {
  group('Dark Mode Tests', () {
    testWidgets('TrackingOrderScreen should adapt to dark mode', (
      WidgetTester tester,
    ) async {
      // Test light mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TrackingOrderScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      // Find scaffold and verify light mode background
      final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(lightScaffold.backgroundColor, AppColors.lightBackground);

      // Test dark mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TrackingOrderScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find scaffold and verify dark mode background
      final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(darkScaffold.backgroundColor, AppColors.darkBackground);
    });

    testWidgets('ReviewsScreen should adapt to dark mode', (
      WidgetTester tester,
    ) async {
      // Test light mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewsScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      // Find scaffold and verify light mode background
      final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(lightScaffold.backgroundColor, AppColors.lightBackground);

      // Test dark mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ReviewsScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find scaffold and verify dark mode background
      final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(darkScaffold.backgroundColor, AppColors.darkBackground);
    });

    testWidgets('Headers use consistent primary color styling', (
      WidgetTester tester,
    ) async {
      // Test TrackingOrderScreen header
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TrackingOrderScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final trackingAppBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(trackingAppBar.backgroundColor, AppColors.primary);

      // Test ReviewsScreen header
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReviewsScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final reviewsAppBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(reviewsAppBar.backgroundColor, AppColors.primary);
    });
  });
}
