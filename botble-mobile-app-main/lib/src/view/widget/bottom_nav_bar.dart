import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'dart:async';
import 'package:martfury/src/view/screen/cart_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _cartCount = 0;
  StreamSubscription<int>? _cartCountSubscription;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    _setupCartCountListener();
  }

  @override
  void dispose() {
    _cartCountSubscription?.cancel();
    super.dispose();
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

  Widget _buildCartIcon({required bool isActive}) {
    final cartIcon = SvgPicture.asset(
      'assets/images/icons/cart.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.primary : AppColors.getSecondaryTextColor(context),
        BlendMode.srcIn,
      ),
    );

    if (_cartCount == 0) {
      return cartIcon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        cartIcon,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.getCardBackgroundColor(context),
                width: 1,
              ),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              _cartCount > 99 ? '99+' : _cartCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int navBarIndex = widget.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: navBarIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
            return;
          }
          widget.onTap(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.getSurfaceColor(context),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.getSecondaryTextColor(context),
        selectedLabelStyle: kAppTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: kAppTextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'nav.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: 'nav.category'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore),
            label: 'nav.explorer'.tr(),
          ),
          BottomNavigationBarItem(
            icon: _buildCartIcon(isActive: false),
            activeIcon: _buildCartIcon(isActive: true),
            label: 'nav.cart'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
    );
  }
}
