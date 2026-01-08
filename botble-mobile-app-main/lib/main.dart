import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:martfury/core/app_config.dart';
import 'package:martfury/src/view/screen/splash_screen.dart';
import 'package:martfury/src/utils/restart_widget.dart';
import 'package:martfury/src/theme/app_theme.dart';
import 'package:martfury/src/service/language_service.dart';
import 'package:martfury/src/service/notification_service.dart';
import 'package:martfury/src/service/custom_translation_loader.dart';
import 'package:martfury/src/service/cart_service.dart';
import 'package:martfury/src/service/wishlist_service.dart';
import 'package:martfury/src/service/compare_service.dart';
import 'package:martfury/src/controller/theme_controller.dart';
import 'package:martfury/src/service/analytics_service.dart';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) => '';
  }

  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    // Firebase initialization failed - app will continue without push notifications
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize app configuration
  await AppConfig.load();
  await EasyLocalization.ensureInitialized();
  
  // Check if API URL has changed and clear cart, wishlist, and compare data if needed
  await Future.wait([
    CartService.checkAndClearCartOnApiChange(),
    WishlistService.checkAndClearWishlistOnApiChange(),
    CompareService.checkAndClearCompareOnApiChange(),
  ]);

  // Initialize FCM push notifications only if Firebase is available
  if (firebaseInitialized) {
    try {
      await NotificationService.initialize();
    } catch (e) {
      // Notification service initialization failed - app will continue without notifications
      debugPrint('Notification service initialization failed: $e');
    }
  } else {
    // Firebase not initialized - notifications will not be available
    debugPrint(
      'Firebase not initialized - notifications will not be available',
    );
  }

  // Get the default language from environment
  final defaultLanguageCode = AppConfig.defaultLanguage;
  final defaultLocale = Locale(defaultLanguageCode);
  
  // Initialize theme controller
  Get.put(ThemeController());

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
        Locale('ar'), // Arabic (RTL)
        Locale('bn'), // Bengali
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('hi'), // Hindi
        Locale('id'), // Indonesian
      ],
      path: 'unused', // Path is unused with custom loader
      assetLoader: const CustomTranslationLoader(),
      fallbackLocale: const Locale('en'),
      startLocale: defaultLocale, // Set the initial locale from environment
      child: const RestartWidget(child: MyApp()),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ui.TextDirection _textDirection = ui.TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _loadTextDirection();
  }

  Future<void> _loadTextDirection() async {
    final textDirection = await LanguageService.getTextDirection();
    if (mounted) {
      setState(() {
        _textDirection = textDirection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Directionality(
      textDirection: _textDirection,
      child: Obx(() => GetMaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        navigatorObservers: [AnalyticsService.observer],
      )),
    );
  }
}
