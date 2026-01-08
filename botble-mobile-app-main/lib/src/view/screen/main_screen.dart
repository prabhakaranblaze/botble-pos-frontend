import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/view/widget/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'category_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'product_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final Widget? productScreen;
  const MainScreen({
    super.key, 
    this.initialIndex = 0,
    this.productScreen,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final List<Widget> _screens = [];
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    if (mounted) {
      setState(() {
        _screens.clear();
        _screens.addAll([
          const HomeScreen(),
          const CategoryScreen(),
          widget.productScreen ?? const ProductScreen(),
          const CartScreen(),
          const ProfileScreen(),
        ]);
      });
    }
  }

  Future<bool> _onWillPop() async {
    // If we're not on the home tab, go to home tab first
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // Don't exit the app
    }

    // If we're on the home tab, implement double-tap to exit
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      // Show a snackbar to inform user about double-tap to exit
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.press_back_again_to_exit'.tr()),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false; // Don't exit the app
    }

    // Double-tap detected, exit the app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_screens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false, // We handle the back button ourselves
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
