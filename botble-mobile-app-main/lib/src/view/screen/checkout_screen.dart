import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/view/screen/cart_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:martfury/src/utils/robust_webview.dart';
import 'package:martfury/src/service/analytics_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String cartId;

  const CheckoutScreen({super.key, required this.cartId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _checkoutUrl;
  Map<String, String>? _headers;
  bool _shouldRefresh = false;

  @override
  void initState() {
    super.initState();
    _prepareCheckoutUrl();

    // Log begin checkout event
    AnalyticsService.logBeginCheckout();
    AnalyticsService.logScreenView(screenName: 'Checkout');
  }

  void _handleCheckoutComplete() async {
    // Log purchase event (basic without specific details since it's webview based)
    await AnalyticsService.logPurchase(transactionId: widget.cartId);

    // Clear cart data since checkout is complete
    await CartService.clearCartId();
    await CartService.clearCartProducts();

    if (mounted) {
      // Pop back to home page
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleContinueShopping() async {
    // Clear cart data since checkout is complete
    await CartService.clearCartId();
    await CartService.clearCartProducts();

    if (mounted) {
      // Navigate back to home page for continue shopping
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'checkout.order_placed_successfully'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handle503Error() {
    if (mounted) {
      // Show error dialog with options
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('checkout.service_unavailable'.tr()),
            content: Text('checkout.service_unavailable_message'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  _refreshWebView(); // Retry
                },
                child: Text('common.retry'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  _handleCheckoutComplete(); // Assume success and go home
                },
                child: Text('checkout.continue_shopping'.tr()),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _prepareCheckoutUrl() async {
    final token = await TokenService.getToken();
    if (!mounted) return;

    final url =
        '${AppConfig.apiBaseUrl}/api/v1/ecommerce/checkout/cart/${widget.cartId}';
    final headers = <String, String>{
      'X-API-KEY': AppConfig.apiKey,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };

    // Only add Authorization header if user is logged in
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('checkout headers: $headers');
    print('checkout url: $url');

    if (mounted) {
      setState(() {
        _checkoutUrl = url;
        _headers = headers;
      });
    }
  }

  void _refreshWebView() {
    setState(() {
      _shouldRefresh = true;
    });
    // Reset the flag after a short delay to trigger rebuild
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _shouldRefresh = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshWebView,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _checkoutUrl != null && _headers != null && !_shouldRefresh
              ? RobustWebView(
                key: ValueKey(
                  _checkoutUrl! +
                      DateTime.now().millisecondsSinceEpoch.toString(),
                ),
                url: _checkoutUrl!,
                headers: _headers!,
                onWebResourceError: (error) {
                  // Handle 503 errors specifically
                  if (error.description.contains('503') ||
                      error.description.contains('Service Unavailable')) {
                    _handle503Error();
                  }
                },
                onHttpError: (error) {
                  // Handle HTTP 503 errors
                  if (error.response?.statusCode == 503) {
                    _handle503Error();
                  }
                },
                onNavigationRequest: (NavigationRequest request) {
                  // Check if URL matches base URL or thank you page
                  if (request.url == AppConfig.apiBaseUrl ||
                      request.url == '${AppConfig.apiBaseUrl}/' ||
                      request.url.startsWith(
                        '${AppConfig.apiBaseUrl}/thank-you',
                      )) {
                    _handleCheckoutComplete();
                    return NavigationDecision.prevent;
                  }

                  // Check if URL is cart page and redirect to cart screen
                  if (request.url.startsWith('${AppConfig.apiBaseUrl}/cart')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                    return NavigationDecision.prevent;
                  }

                  // Handle continue shopping or home page navigation
                  if (_isContinueShoppingUrl(request.url)) {
                    _handleContinueShopping();
                    return NavigationDecision.prevent;
                  }

                  // Handle external URLs that might cause 503 errors
                  if (!request.url.startsWith(AppConfig.apiBaseUrl)) {
                    // External URL - handle gracefully
                    _handleExternalNavigation(request.url);
                    return NavigationDecision.prevent;
                  }

                  return NavigationDecision.navigate;
                },
                
              )
              : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Preparing checkout...'),
                  ],
                ),
              ),
    );
  }

  bool _isContinueShoppingUrl(String url) {
    // Check for various continue shopping URL patterns
    final patterns = [
      '/continue-shopping',
      '/shop',
      '/products',
      '/home',
      '/category',
      '/categories',
      '/?continue=shopping',
      '/?action=continue',
    ];

    for (String pattern in patterns) {
      if (url.contains(pattern)) {
        return true;
      }
    }

    // Check if it's just the base URL (home page)
    if (url == AppConfig.apiBaseUrl ||
        url == '${AppConfig.apiBaseUrl}/' ||
        url.endsWith('/') && url.length <= AppConfig.apiBaseUrl.length + 1) {
      return true;
    }

    return false;
  }

  void _handleExternalNavigation(String url) {
    if (mounted) {
      // Show dialog asking user what to do
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('checkout.external_link'.tr()),
            content: Text('checkout.external_link_message'.tr()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Stay in checkout
                },
                child: Text('common.cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  _handleContinueShopping(); // Go home
                },
                child: Text('checkout.continue_shopping'.tr()),
              ),
            ],
          );
        },
      );
    }
  }
}
