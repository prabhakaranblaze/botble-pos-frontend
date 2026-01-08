import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:martfury/src/view/screen/order_detail_screen.dart';
import 'package:martfury/src/model/order.dart';
import 'package:martfury/src/theme/app_theme.dart';
import 'package:martfury/src/theme/app_colors.dart';

void main() {
  group('OrderDetailScreen Dark Mode Tests', () {
    // Create a mock order for testing
    final mockOrder = Order(
      id: 1,
      code: 'SF-10000049',
      status: OrderStatus(value: 'pending', label: 'Pending'),
      statusHtml: '<span class="pending">Pending</span>',
      customer: OrderCustomer(
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+1234567890',
      ),
      paymentMethod: OrderMethod(value: 'credit_card', label: 'Credit Card'),
      paymentStatus: OrderStatus(value: 'paid', label: 'Paid'),
      paymentStatusHtml: '<span class="paid">Paid</span>',
      shippingMethod: OrderMethod(value: 'standard', label: 'Standard'),
      shippingStatus: OrderStatus(value: 'processing', label: 'Processing'),
      shippingStatusHtml: '<span class="processing">Processing</span>',
      products: [],
      productsCount: 0,
      createdAt: DateTime.now().toIso8601String(),
      amount: '100.00',
      amountFormatted: '\$100.00',
      taxAmount: '10.00',
      taxAmountFormatted: '\$10.00',
      shippingAmount: '5.00',
      shippingAmountFormatted: '\$5.00',
    );

    testWidgets('OrderDetailScreen adapts to light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderDetailScreen(order: mockOrder),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      // Find scaffold and verify light mode background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.lightBackground);

      // Verify header has consistent primary color
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFFFFB800));
    });

    testWidgets('OrderDetailScreen adapts to dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: OrderDetailScreen(order: mockOrder),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Find scaffold and verify dark mode background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.darkBackground);

      // Verify header has consistent primary color
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFFFFB800));
    });

    testWidgets('OrderDetailScreen renders without errors in both themes', (WidgetTester tester) async {
      // Test light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderDetailScreen(order: mockOrder),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      expect(find.byType(OrderDetailScreen), findsOneWidget);

      // Test dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: OrderDetailScreen(order: mockOrder),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailScreen), findsOneWidget);
    });
  });
}
