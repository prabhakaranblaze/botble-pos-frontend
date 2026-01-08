import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'dart:async';
import 'package:martfury/src/view/screen/search_screen.dart';
import 'package:martfury/src/view/screen/cart_screen.dart';
import 'package:martfury/src/view/screen/notification_screen.dart';
import 'package:martfury/src/view/screen/sign_in_screen.dart';
import 'package:martfury/src/controller/notification_controller.dart';
import 'package:martfury/src/service/token_service.dart';
import 'package:get/get.dart' hide Trans;
import 'dart:ui' as ui;

class Header extends StatefulWidget {
  final bool isCollapsed;
  const Header({super.key, this.isCollapsed = false});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  int _cartCount = 0;
  StreamSubscription<int>? _cartCountSubscription;
  late NotificationController _notificationController;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _setupCartCountListener();
    _initializeNotificationController();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _cartCountSubscription?.cancel();
    super.dispose();
  }

  void _initializeNotificationController() {
    // Check if NotificationController is already registered
    if (Get.isRegistered<NotificationController>()) {
      _notificationController = Get.find<NotificationController>();
    } else {
      _notificationController = Get.put(NotificationController());
    }
  }

  Future<void> _loadCartCount() async {
    final count = await CartService.getCartCount();
    if (mounted) {
      setState(() {
        _cartCount = count;
      });
    }
  }

  void _setupCartCountListener() {
    _cartCountSubscription = CartService.cartCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _cartCount = count;
        });
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    final token = await TokenService.getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
                Row(
                  children: [
                    // Cart icon with badge
                    Stack(
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/icons/cart.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            );
                          },
                        ),
                        if (_cartCount > 0)
                          Positioned(
                            right: isRtl ? null : 6,
                            left: isRtl ? 6 : null,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                _cartCount.toString(),
                                style: kAppTextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Notification bell icon with badge
                    Stack(
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/icons/bell-solid.svg',
                            width: 30,
                            height: 30,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () async {
                            // Check if user is logged in
                            final token = await TokenService.getToken();
                            if (token != null) {
                              // User is logged in, navigate to notifications
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationScreen(),
                                  ),
                                );
                              }
                            } else {
                              // User is not logged in, navigate to sign in
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignInScreen(),
                                  ),
                                ).then((_) async {
                                  // Refresh login status
                                  await _checkLoginStatus();
                                  // Re-initialize notification controller if needed
                                  if (_isLoggedIn) {
                                    _notificationController.checkAuthAndLoadData();
                                  }
                                  // Check if user logged in after returning
                                  final newToken = await TokenService.getToken();
                                  if (newToken != null && context.mounted) {
                                    // User logged in, now navigate to notifications
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NotificationScreen(),
                                      ),
                                    );
                                  }
                                });
                              }
                            }
                          },
                        ),
                        if (_isLoggedIn)
                          Obx(() {
                            final unreadCount = _notificationController.notificationStats.value?.unread ?? 0;
                            if (unreadCount > 0) {
                              return Positioned(
                                right: isRtl ? null : 6,
                                left: isRtl ? 6 : null,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: kAppTextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (!widget.isCollapsed) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (isRtl) ...[
                        // In RTL: text first, then search button on the left
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              context.tr('common.search_placeholder'),
                              style: kAppTextStyle(
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCardBackground
                                    : Colors.black,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: IconButton(
                            icon: SvgPicture.asset(
                              'assets/images/icons/search.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ] else ...[
                        // In LTR: text first, then search button on the right
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              context.tr('common.search_placeholder'),
                              style: kAppTextStyle(
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCardBackground
                                    : Colors.black,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: IconButton(
                            icon: SvgPicture.asset(
                              'assets/images/icons/search.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
