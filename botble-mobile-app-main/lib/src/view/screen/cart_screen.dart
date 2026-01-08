import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/constants/coupon_error_codes.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:martfury/src/service/currency_change_service.dart';
import 'package:martfury/src/service/language_change_service.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/utils/back_button_handler.dart';
import 'package:martfury/src/view/screen/checkout_screen.dart';
import 'package:martfury/src/view/screen/search_screen.dart';
import 'package:martfury/src/view/screen/wishlist_screen.dart';
import 'package:martfury/src/view/screen/sign_in_screen.dart';
import 'package:martfury/core/app_config.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _promoCodeController = TextEditingController();
  bool _isLoading = true;
  bool _isUpdatingQuantity = false;
  String _error = '';
  Map<String, dynamic> _cartDetail = {};
  final CartService _cartService = CartService();
  StreamSubscription<int>? _cartCountSubscription;
  StreamSubscription<String>? _currencyChangeSubscription;
  StreamSubscription<String>? _languageChangeSubscription;
  int _lastCartCount = 0;
  final Set<String> _deletingItems = <String>{}; // Track items being deleted

  // Quantity input controllers
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};
  final Map<String, bool> _editingQuantities = {};

  // Debouncing for quantity updates
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, int> _pendingQuantityUpdates = {};
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initializeCartData();
    _setupCartCountListener();
    _setupCurrencyChangeListener();
    _setupLanguageChangeListener();
  }

  Future<void> _initializeCartData() async {
    // Get initial cart count
    _lastCartCount = await CartService.getCartCount();
    _loadCartDetail();
  }

  void _setupCartCountListener() {
    // Listen to cart count changes to refresh cart data when products are added
    _cartCountSubscription = CartService.cartCountStream.listen((newCount) {
      // Only refresh if cart count has actually changed and increased
      // (indicating a product was added)
      if (newCount > _lastCartCount && mounted) {
        _lastCartCount = newCount;
        // Clear cache and reload cart data when products are added
        _loadCartDetail(showLoading: false);
      } else {
        _lastCartCount = newCount;
      }
    });
  }

  void _setupCurrencyChangeListener() {
    // Listen to currency changes to refresh cart data with new currency formatting
    _currencyChangeSubscription = CurrencyChangeService.currencyChangeStream
        .listen((newCurrency) {
          if (mounted) {
            // Reload cart data to get updated prices in new currency
            _loadCartDetail(showLoading: false);
          }
        });
  }

  void _setupLanguageChangeListener() {
    // Listen to language changes to refresh cart data with new language
    _languageChangeSubscription = LanguageChangeService.languageChangeStream
        .listen((newLanguage) {
          if (mounted) {
            // Reload cart data to get updated text in new language
            _loadCartDetail(showLoading: false);
          }
        });
  }

  /// Clears cart cache and reloads cart data
  /// This method should be called when products are added to cart from other screens
  Future<void> clearCacheAndReload() async {
    await _loadCartDetail(showLoading: false);
  }

  Future<void> _loadCartDetail({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final cartId = await CartService.getCartId();

      if (cartId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final cartDetail = await _cartService.getCartDetail(cartId);

      print('cart details: $cartDetail');

      // The backend handles coupon storage with the cart

      if (mounted) {
        setState(() {
          _cartDetail = cartDetail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if the error is due to cart being cleared
        if (e.toString().contains('Cart not found. Cart has been cleared.')) {
          setState(() {
            _cartDetail = {};
            _isLoading = false;
            _error = '';
          });
          // Show info message instead of error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your cart has been cleared',
                style: kAppTextStyle(),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load cart: ${e.toString()}',
                style: kAppTextStyle(),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Check if a translation key exists by comparing the translated text with the key
  /// If they are the same, it means the translation doesn't exist
  bool _translationExists(String key) {
    final translatedText = key.tr();
    return translatedText != key;
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _cartCountSubscription?.cancel();
    _currencyChangeSubscription?.cancel();
    _languageChangeSubscription?.cancel();

    // Dispose quantity controllers and focus nodes
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _quantityFocusNodes.values) {
      focusNode.dispose();
    }

    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler.createModalPopScope(
      context: context,
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          title: Text(
            'cart.cart'.tr(),
            style: kAppTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/icons/wishlist.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WishlistScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadCartDetail,
            ),
          ],
        ),
        body:
            _isLoading
                ? _buildLoadingState()
                : _error.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'cart.error_loading'.tr(),
                        style: kAppTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        style: kAppTextStyle(
                          fontSize: 14,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCartDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'common.retry'.tr(),
                          style: kAppTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    // Free shipping banner
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.getPrimaryTextColor(context),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                          if (_translationExists('cart.free_shipping')) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  color: AppColors.getCardBackgroundColor(
                                    context,
                                  ),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'cart.free_shipping'.tr(),
                                  style: kAppTextStyle(
                                    color: AppColors.getCardBackgroundColor(
                                      context,
                                    ),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    if (_cartDetail['cart_items'] == null ||
                        (_cartDetail['cart_items'] is List &&
                            (_cartDetail['cart_items'] as List).isEmpty) ||
                        (_cartDetail['cart_items'] is Map &&
                            (_cartDetail['cart_items'] as Map).isEmpty))
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.getSurfaceColor(context),
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/icons/cart.svg',
                                  width: 48,
                                  height: 48,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.getHintTextColor(context),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'cart.empty_cart'.tr(),
                                style: kAppTextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getPrimaryTextColor(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'cart.continue_shopping'.tr(),
                                style: kAppTextStyle(
                                  fontSize: 14,
                                  color: AppColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_cartDetail['cart_items'] is Map)
                      Expanded(
                        child: Column(
                          children: [
                            // Cart items list - now scrollable
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount:
                                    (_cartDetail['cart_items']
                                            as Map<String, dynamic>)
                                        .length,
                                itemBuilder: (context, index) {
                                  final entry = (_cartDetail['cart_items']
                                          as Map<String, dynamic>)
                                      .entries
                                      .elementAt(index);
                                  return Column(
                                    children: [
                                      _buildCartItem(
                                        rowId: entry.key,
                                        productId: entry.value['id'].toString(),
                                        imageUrl:
                                            entry
                                                .value['cart_options']?['image'] ??
                                            '',
                                        name: entry.value['name'] ?? '',
                                        variant:
                                            entry
                                                .value['cart_options']?['attributes'] ??
                                            '',
                                        priceFormatted:
                                            entry.value['price_formatted'],
                                        quantity:
                                            entry.value['quantity'] as int? ??
                                            1,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                },
                              ),
                            ),
                            // Bottom section with promo code, totals, and checkout button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.getBackgroundColor(context),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  16,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _promoCodeController,
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'cart.promo_code'.tr(),
                                              hintStyle: kAppTextStyle(
                                                color:
                                                    AppColors.getHintTextColor(
                                                      context,
                                                    ),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  AppColors.getCardBackgroundColor(
                                                    context,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.getBorderColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                borderSide: BorderSide(
                                                  color:
                                                      AppColors.getBorderColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 14,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          onPressed:
                                              _promoCodeController.text.isEmpty
                                                  ? null
                                                  : () async {
                                                    if (!mounted) return;
                                                    final state = this;
                                                    final scaffoldMessenger =
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        );
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    try {
                                                      final cartId =
                                                          await CartService.getCartId();
                                                      if (cartId != null) {
                                                        final response =
                                                            await _cartService
                                                                .applyCoupon(
                                                                  couponCode:
                                                                      _promoCodeController
                                                                          .text,
                                                                  cartId:
                                                                      cartId,
                                                                );

                                                        if (response['error'] ==
                                                                false ||
                                                            response['error'] ==
                                                                null) {
                                                          if (state.mounted) {
                                                            scaffoldMessenger.showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  response['message'] ??
                                                                      'cart.coupon_applied'
                                                                          .tr(),
                                                                ),
                                                                backgroundColor:
                                                                    AppColors
                                                                        .success,
                                                              ),
                                                            );
                                                            _promoCodeController
                                                                .clear();
                                                            _loadCartDetail(
                                                              showLoading:
                                                                  false,
                                                            );
                                                          }
                                                        } else {
                                                          if (state.mounted) {
                                                            final errorCode =
                                                                response['data']?['error_code'] ??
                                                                response['error_code'];
                                                            final errorMessage =
                                                                CouponErrorCodes.getErrorMessage(
                                                                  errorCode,
                                                                  response['message'],
                                                                );

                                                            scaffoldMessenger.showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  errorMessage,
                                                                ),
                                                                backgroundColor:
                                                                    AppColors
                                                                        .error,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    } catch (e) {
                                                      if (state.mounted) {
                                                        String errorMessage =
                                                            e.toString();
                                                        if (errorMessage.startsWith(
                                                          'Exception: Failed to apply coupon: Exception: ',
                                                        )) {
                                                          errorMessage =
                                                              errorMessage
                                                                  .substring(
                                                                    'Exception: Failed to apply coupon: Exception: '
                                                                        .length,
                                                                  );
                                                        } else if (errorMessage
                                                            .startsWith(
                                                              'Exception: Failed to apply coupon: ',
                                                            )) {
                                                          errorMessage =
                                                              errorMessage
                                                                  .substring(
                                                                    'Exception: Failed to apply coupon: '
                                                                        .length,
                                                                  );
                                                        } else if (errorMessage
                                                            .startsWith(
                                                              'Exception: ',
                                                            )) {
                                                          errorMessage =
                                                              errorMessage
                                                                  .substring(
                                                                    'Exception: '
                                                                        .length,
                                                                  );
                                                        }

                                                        scaffoldMessenger
                                                            .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  errorMessage,
                                                                ),
                                                                backgroundColor:
                                                                    AppColors
                                                                        .error,
                                                              ),
                                                            );
                                                      }
                                                    }
                                                  },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _promoCodeController
                                                        .text
                                                        .isEmpty
                                                    ? AppColors.getBorderColor(
                                                      context,
                                                    )
                                                    : AppColors.primary,
                                            disabledBackgroundColor:
                                                AppColors.getBorderColor(
                                                  context,
                                                ),
                                            disabledForegroundColor:
                                                AppColors.getPrimaryTextColor(
                                                  context,
                                                ),
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'cart.apply'.tr(),
                                            style: kAppTextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _promoCodeController
                                                          .text
                                                          .isEmpty
                                                      ? AppColors.getPrimaryTextColor(
                                                        context,
                                                      )
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.getCardBackgroundColor(
                                          context,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.getBorderColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Subtotal row - only show if sub_total_formatted is not null
                                          if (_cartDetail['sub_total_formatted'] !=
                                              null) ...[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'cart.subtotal'.tr(
                                                    namedArgs: {
                                                      'count':
                                                          _cartDetail['count']
                                                              .toString(),
                                                    },
                                                  ),
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  _cartDetail['sub_total_formatted'],
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.getPrimaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          // Tax row
                                          if (_cartDetail['tax_amount'] !=
                                                  null &&
                                              (_cartDetail['tax_amount']
                                                      as num) >
                                                  0) ...[
                                            // Add spacing only if subtotal was shown, otherwise this is the first item
                                            if (_cartDetail['sub_total_formatted'] !=
                                                null)
                                              const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'cart.tax'.tr(),
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  _cartDetail['tax_amount_formatted'] ??
                                                      '0.00',
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.getPrimaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (_cartDetail['applied_coupon_code'] !=
                                              null) ...[
                                            // Add spacing only if subtotal or tax was shown, otherwise this is the first item
                                            if (_cartDetail['sub_total_formatted'] !=
                                                    null ||
                                                (_cartDetail['tax_amount'] !=
                                                        null &&
                                                    (_cartDetail['tax_amount']
                                                            as num) >
                                                        0))
                                              const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'cart.coupon'.tr(),
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      _cartDetail['applied_coupon_code'],
                                                      style: kAppTextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.close,
                                                        size: 16,
                                                        color:
                                                            AppColors.getSecondaryTextColor(
                                                              context,
                                                            ),
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              _showRemoveCouponConfirmation(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'cart.discount'.tr(),
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors.getSecondaryTextColor(
                                                          context,
                                                        ),
                                                  ),
                                                ),
                                                Text(
                                                  '-${_cartDetail['coupon_discount_amount_formatted']}',
                                                  style: kAppTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          // Only show divider and spacing if there are any items above (subtotal, tax, or coupon)
                                          if (_cartDetail['sub_total_formatted'] !=
                                                  null ||
                                              (_cartDetail['tax_amount'] !=
                                                      null &&
                                                  (_cartDetail['tax_amount']
                                                          as num) >
                                                      0) ||
                                              _cartDetail['applied_coupon_code'] !=
                                                  null) ...[
                                            const SizedBox(height: 8),
                                            const Divider(),
                                            const SizedBox(height: 8),
                                          ],
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'cart.total'.tr(),
                                                style: kAppTextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.getPrimaryTextColor(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                _cartDetail['order_total_formatted'],
                                                style: kAppTextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            _cartDetail['cart_items'] is Map &&
                                                    (_cartDetail['cart_items']
                                                            as Map)
                                                        .isNotEmpty &&
                                                    !_isUpdatingQuantity
                                                ? () async {
                                                  await _handleCheckoutPressed();
                                                }
                                                : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'cart.proceed_to_checkout'.tr(),
                                          style: kAppTextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Text(
                            'cart.invalid_cart_content_format'.tr(),
                            style: kAppTextStyle(
                              color: AppColors.getPrimaryTextColor(context),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCartItem({
    required String rowId,
    required String productId,
    required String imageUrl,
    required String name,
    required String variant,
    required String priceFormatted,
    required int quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: kAppTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getPrimaryTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      variant,
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceFormatted,
                            style: kAppTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.getBorderColor(context),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: GestureDetector(
                              onTap: () => _handleQuantityTap(rowId, false),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: AppColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            alignment: Alignment.center,
                            child: _buildQuantityInput(rowId, quantity),
                          ),
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: GestureDetector(
                              onTap: () => _handleQuantityTap(rowId, true),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 14,
                                  color: AppColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon:
                  _deletingItems.contains(rowId)
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.error,
                          ),
                        ),
                      )
                      : const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
              onPressed:
                  _deletingItems.contains(rowId)
                      ? null // Disable button when deleting
                      : () => _showRemoveItemConfirmation(rowId, productId),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityInput(String rowId, int quantity) {
    // Initialize controller if not exists
    _initializeQuantityController(rowId, quantity);

    final isEditing = _editingQuantities[rowId] ?? false;

    if (isEditing) {
      return SizedBox(
        width: 28,
        child: TextField(
          controller: _quantityControllers[rowId],
          focusNode: _quantityFocusNodes[rowId],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: kAppTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.getPrimaryTextColor(context),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: (value) => _onQuantityTextChanged(rowId, value),
          onSubmitted: (value) {
            _validateAndUpdateQuantity(rowId);
            _quantityFocusNodes[rowId]?.unfocus();
          },
          onTapOutside: (event) {
            _validateAndUpdateQuantity(rowId);
            _quantityFocusNodes[rowId]?.unfocus();
          },
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _onQuantityTap(rowId),
        child: Container(
          height: 26,
          alignment: Alignment.center,
          child: Text(
            quantity.toString(),
            style: kAppTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.getPrimaryTextColor(context),
            ),
          ),
        ),
      );
    }
  }

  void _initializeQuantityController(String rowId, int quantity) {
    if (!_quantityControllers.containsKey(rowId)) {
      _quantityControllers[rowId] = TextEditingController(
        text: quantity.toString(),
      );
      _quantityFocusNodes[rowId] = FocusNode();
      _editingQuantities[rowId] = false;

      _quantityFocusNodes[rowId]!.addListener(() {
        setState(() {
          _editingQuantities[rowId] = _quantityFocusNodes[rowId]!.hasFocus;
        });

        if (!_quantityFocusNodes[rowId]!.hasFocus) {
          _validateAndUpdateQuantity(rowId);
        }
      });
    }
  }

  void _onQuantityTextChanged(String rowId, String value) {
    // Only allow numbers, remove any non-digit characters
    final String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanValue.isEmpty) {
      // If empty, set to minimum value of 1
      _quantityControllers[rowId]!.text = '1';
      _quantityControllers[rowId]!.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityControllers[rowId]!.text.length),
      );
      return;
    }

    final int? newQuantity = int.tryParse(cleanValue);
    if (newQuantity != null) {
      // Ensure minimum value is 1
      final int validQuantity = newQuantity < 1 ? 1 : newQuantity;

      // Update controller only if the clean value is different from input
      if (cleanValue != value) {
        _quantityControllers[rowId]!.text = validQuantity.toString();
        _quantityControllers[rowId]!.selection = TextSelection.fromPosition(
          TextPosition(offset: _quantityControllers[rowId]!.text.length),
        );
      }
    }
  }

  void _onQuantityTap(String rowId) {
    setState(() {
      _editingQuantities[rowId] = true;
    });
    _quantityFocusNodes[rowId]?.requestFocus();
    // Select all text when tapping
    final controller = _quantityControllers[rowId];
    if (controller != null) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  void _validateAndUpdateQuantity(String rowId) {
    if (_cartDetail['cart_items'] is! Map) return;

    final cartItems = _cartDetail['cart_items'] as Map<String, dynamic>;
    final cartItem = cartItems[rowId];
    if (cartItem == null) return;

    final currentQuantity = cartItem['quantity'] as int? ?? 1;
    final inputText = _quantityControllers[rowId]?.text ?? '1';

    int validQuantity = int.tryParse(inputText) ?? 1;
    bool wasAdjusted = false;

    // Ensure quantity is at least 1
    if (validQuantity < 1) {
      validQuantity = 1;
      wasAdjusted = true;
    }

    // Update the controller with the validated quantity
    _quantityControllers[rowId]?.text = validQuantity.toString();

    // Show message if quantity was adjusted to minimum
    if (wasAdjusted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cart.quantity_minimum_message'.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
    }

    // Only update if quantity actually changed
    if (validQuantity != currentQuantity) {
      _updateQuantityValue(rowId, validQuantity);
    }
  }

  Future<void> _updateQuantityValue(String rowId, int newQuantity) async {
    if (_cartDetail['cart_items'] is! Map) return;

    final cartItems = _cartDetail['cart_items'] as Map<String, dynamic>;
    final cartItem = cartItems[rowId];
    if (cartItem == null) return;

    final currentQuantity = cartItem['quantity'] as int? ?? 1;

    if (newQuantity < 1) return;

    // Update UI immediately
    setState(() {
      (_cartDetail['cart_items'] as Map<String, dynamic>)[rowId]['quantity'] =
          newQuantity;
      _isUpdatingQuantity = true;
    });

    try {
      String? cartId = await CartService.getCartId();
      await _cartService.updateCartItem(
        cartItemId: cartId ?? '',
        productId: cartItem['id'].toString(),
        quantity: newQuantity,
      );

      await _loadCartDetail(showLoading: false);

      // Only show success message after API call and reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.quantity_updated'.tr(), style: kAppTextStyle()),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      // Revert the quantity if API call fails
      if (mounted) {
        setState(() {
          (_cartDetail['cart_items']
                  as Map<String, dynamic>)[rowId]['quantity'] =
              currentQuantity;
        });

        // Also revert the controller
        _quantityControllers[rowId]?.text = currentQuantity.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.failed_to_update'.tr(), style: kAppTextStyle()),
            backgroundColor: AppColors.error,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingQuantity = false;
        });
      }
    }
  }

  /// Handle quantity tap with immediate UI update and debounced API call
  void _handleQuantityTap(String rowId, bool increment) {
    if (_cartDetail['cart_items'] is! Map) return;

    final cartItems = _cartDetail['cart_items'] as Map<String, dynamic>;
    final cartItem = cartItems[rowId];
    if (cartItem == null) return;

    final currentQuantity = cartItem['quantity'] as int? ?? 1;
    final newQuantity = increment ? currentQuantity + 1 : currentQuantity - 1;

    if (newQuantity < 1) return;

    // Update UI immediately for better responsiveness
    setState(() {
      (_cartDetail['cart_items'] as Map<String, dynamic>)[rowId]['quantity'] =
          newQuantity;
    });

    // Update the controller as well
    _quantityControllers[rowId]?.text = newQuantity.toString();

    // Store the pending update
    _pendingQuantityUpdates[rowId] = newQuantity;

    // Cancel existing timer for this item
    _debounceTimers[rowId]?.cancel();

    // Start new debounced timer
    _debounceTimers[rowId] = Timer(_debounceDuration, () {
      _executeDebouncedQuantityUpdate(rowId);
    });
  }

  /// Execute the actual API call after debounce period
  Future<void> _executeDebouncedQuantityUpdate(String rowId) async {
    final pendingQuantity = _pendingQuantityUpdates[rowId];
    if (pendingQuantity == null) return;

    if (_cartDetail['cart_items'] is! Map) return;

    final cartItems = _cartDetail['cart_items'] as Map<String, dynamic>;
    final cartItem = cartItems[rowId];
    if (cartItem == null) return;

    setState(() {
      _isUpdatingQuantity = true;
    });

    try {
      String? cartId = await CartService.getCartId();
      await _cartService.updateCartItem(
        cartItemId: cartId ?? '',
        productId: cartItem['id'].toString(),
        quantity: pendingQuantity,
      );

      await _loadCartDetail(showLoading: false);

      // Clean up pending update
      _pendingQuantityUpdates.remove(rowId);
      _debounceTimers.remove(rowId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.quantity_updated'.tr(), style: kAppTextStyle()),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      // Revert the quantity if API call fails
      if (mounted) {
        // Get the original quantity from the server or use 1 as fallback
        const originalQuantity = 1; // Will be updated by _loadCartDetail
        setState(() {
          (_cartDetail['cart_items']
                  as Map<String, dynamic>)[rowId]['quantity'] =
              originalQuantity;
        });

        // Also revert the controller
        _quantityControllers[rowId]?.text = originalQuantity.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: kAppTextStyle()),
            backgroundColor: AppColors.error,
          ),
        );

        // Reload to get the correct state from server
        _loadCartDetail(showLoading: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingQuantity = false;
        });
      }
    }
  }

  /// Shows confirmation dialog before removing item from cart
  Future<void> _showRemoveItemConfirmation(
    String rowId,
    String productId,
  ) async {
    final bool? shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'cart.remove_item_confirm'.tr(),
            style: kAppTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryTextColor(context),
            ),
          ),
          content: Text(
            'cart.remove_item_confirm_message'.tr(),
            style: kAppTextStyle(
              fontSize: 16,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'common.cancel'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: Text(
                'common.remove'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      _removeCartItem(rowId, productId);
    }
  }

  Future<void> _showRemoveCouponConfirmation() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            'cart.remove_coupon_confirm'.tr(),
            style: kAppTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryTextColor(context),
            ),
          ),
          content: Text(
            'cart.remove_coupon_confirm_message'.tr(),
            style: kAppTextStyle(
              fontSize: 16,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'common.cancel'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: Text(
                'common.remove'.tr(),
                style: kAppTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      _removeCoupon();
    }
  }

  Future<void> _removeCoupon() async {
    if (!mounted) return;
    final state = this;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final cartId = await CartService.getCartId();
      if (cartId != null) {
        final response = await _cartService.removeCoupon(cartId: cartId);
        if (state.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'cart.coupon_removed'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          _loadCartDetail(showLoading: false);
        }
      }
    } catch (e) {
      if (state.mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeCartItem(String rowId, String productId) async {
    // Add item to deleting set to show loading state
    setState(() {
      _deletingItems.add(rowId);
    });

    try {
      String? cartId = await CartService.getCartId();
      await _cartService.removeCartItem(
        cartItemId: cartId ?? '',
        productId: productId,
      );

      // Refresh cart details
      await _loadCartDetail();

      // Check if cart is now empty and clear everything if so
      if (_cartDetail['cart_items'] == null ||
          (_cartDetail['cart_items'] is List &&
              (_cartDetail['cart_items'] as List).isEmpty) ||
          (_cartDetail['cart_items'] is Map &&
              (_cartDetail['cart_items'] as Map).isEmpty)) {
        // Clear cart ID and local cart data when cart becomes empty
        await CartService.clearCartId();
        await CartService.clearCartProducts();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.item_removed'.tr(), style: kAppTextStyle()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.failed_to_remove'.tr(), style: kAppTextStyle()),
            backgroundColor: AppColors.error,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      // Remove item from deleting set regardless of success or failure
      if (mounted) {
        setState(() {
          _deletingItems.remove(rowId);
        });
      }
    }
  }

  Future<void> _handleCheckoutPressed() async {
    // Check if guest checkout is enabled
    if (AppConfig.enableGuestCheckout) {
      // Guest checkout is enabled, proceed directly to checkout
      await _proceedToCheckout();
    } else {
      // Guest checkout is disabled, check if user is logged in
      final token = await TokenService.getToken();
      if (token != null) {
        // User is logged in, proceed to checkout
        await _proceedToCheckout();
      } else {
        // User is not logged in, redirect to sign in screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        }
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    // Capture the Navigator before the async gap
    final navigator = Navigator.of(context);
    final cartId = await CartService.getCartId();
    if (cartId != null && mounted) {
      navigator.push(
        MaterialPageRoute(builder: (context) => CheckoutScreen(cartId: cartId)),
      );
    }
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildShippingBannerSkeleton(),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Cart items skeleton
              ..._buildCartItemsSkeletons(),

              const SizedBox(height: 20),

              // Promo code skeleton
              _buildPromoCodeSkeleton(),

              const SizedBox(height: 20),

              // Total section skeleton
              _buildTotalSectionSkeleton(),

              const SizedBox(height: 20),

              // Checkout button skeleton
              _buildCheckoutButtonSkeleton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingBannerSkeleton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.getPrimaryTextColor(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          if (_translationExists('cart.free_shipping')) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 100,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCartItemsSkeletons() {
    return List.generate(
      3, // Show 3 skeleton cart items
      (index) => Column(
        children: [_buildCartItemSkeleton(), const SizedBox(height: 12)],
      ),
    );
  }

  Widget _buildCartItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image skeleton
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.getSkeletonColor(context),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name skeleton
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.getSkeletonColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                // Variant skeleton
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price skeleton
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity controls skeleton
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.getBorderColor(context),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.getSurfaceColor(context),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 13,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: AppColors.getSkeletonColor(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.getSurfaceColor(context),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delete button skeleton
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSkeleton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.getCardBackgroundColor(context),
              border: Border.all(color: AppColors.getBorderColor(context)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 90,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 50,
          width: 70,
          decoration: BoxDecoration(
            color: AppColors.getSkeletonColor(context),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSectionSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Column(
        children: [
          // Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Coupon row (optional)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.getSkeletonColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Discount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 70,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.getBorderColor(context),
          ),
          const SizedBox(height: 8),
          // Tax row skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.getSkeletonColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButtonSkeleton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.getSkeletonColor(context),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
