import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/add_edit_address_screen.dart';
import 'package:martfury/src/view/screen/orders_screen.dart';
import 'package:martfury/src/view/screen/tracking_order_screen.dart';
import 'package:martfury/src/view/screen/reviews_screen.dart';
import 'package:martfury/src/view/screen/manage_address_screen.dart';
import 'package:martfury/src/view/screen/wishlist_screen.dart';
import 'package:martfury/src/view/screen/edit_profile_screen.dart';
import 'package:martfury/src/view/screen/forgot_password_screen.dart';
import 'package:martfury/src/theme/app_theme.dart';

void main() {
  group('Header Consistency Tests', () {
    const primaryColor = Color(0xFFFFB800);

    testWidgets('AddEditAddressScreen has consistent header style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AddEditAddressScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('OrdersScreen has consistent header style', (
      WidgetTester tester,
    ) async {
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

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('TrackingOrderScreen has consistent header style', (
      WidgetTester tester,
    ) async {
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

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('ReviewsScreen has consistent header style', (
      WidgetTester tester,
    ) async {
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

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('ManageAddressScreen has consistent header style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManageAddressScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('WishlistScreen has consistent header style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WishlistScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('EditProfileScreen has consistent header style', (
      WidgetTester tester,
    ) async {
      final mockProfileData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'dob': '1990-01-01',
        'avatar': 'https://example.com/avatar.jpg',
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EditProfileScreen(profileData: mockProfileData),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });

    testWidgets('ForgotPasswordScreen has consistent header style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ForgotPasswordScreen(),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, primaryColor);
    });
  });
}
