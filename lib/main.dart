import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'l10n/generated/app_localizations.dart';

import 'core/api/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/connectivity_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/inactivity_provider.dart';
import 'core/providers/currency_provider.dart';
import 'core/providers/pos_mode_provider.dart';
import 'core/providers/update_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/lock_screen.dart';
import 'features/sales/sales_provider.dart';
import 'features/session/session_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/session/register_selection_screen.dart';
import 'features/session/existing_session_dialog.dart';
import 'shared/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop fullscreen support
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'StampSmart POS',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService(storageService);
  final audioService = AudioService();
  await audioService.preload(); // preload beep sound for instant playback

  final inactivityProvider = InactivityProvider(
    lockTimeout: const Duration(minutes: 60),
  );

  // Create AuthProvider first so we can connect the 401 handler
  final authProvider = AuthProvider(apiService, storageService);

  // Create UpdateProvider for app updates
  final updateProvider = UpdateProvider(apiService);

  // Connect API 401 handler to trigger automatic logout
  apiService.onUnauthorized = () {
    debugPrint('🔐 AUTO-LOGOUT: 401 detected, logging out user');
    authProvider.logout();
  };

  // Check for updates on startup (non-blocking)
  updateProvider.checkForUpdate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => PosModeProvider()),
        ChangeNotifierProvider.value(value: inactivityProvider),
        ChangeNotifierProvider.value(value: updateProvider),
        Provider.value(value: apiService),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
            create: (_) => SalesProvider(apiService, audioService)),
        ChangeNotifierProvider(
            create: (_) => SessionProvider(apiService, storageService)),
      ],
      child: MyApp(inactivityProvider: inactivityProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  final InactivityProvider inactivityProvider;

  const MyApp({super.key, required this.inactivityProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return InactivityDetector(
          inactivityProvider: inactivityProvider,
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // Localization
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocaleProvider.supportedLocales,

            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary, brightness: Brightness.light),
              textTheme: GoogleFonts.interTextTheme(),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.surface,
                elevation: 0,
                titleTextStyle: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              cardTheme: CardThemeData(
                color: AppColors.surface,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2)),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            home: const AuthWrapper(),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = false;
  bool _hasChecked = false;
  bool _trackingStarted = false;

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, SessionProvider, InactivityProvider>(
      builder: (context, auth, session, inactivity, child) {
        debugPrint(
            '🔵 AuthWrapper: auth=${auth.isAuthenticated}, session=${session.hasActiveSession}, locked=${inactivity.isLocked}, checking=$_isChecking, checked=$_hasChecked');

        // NOT authenticated
        if (!auth.isAuthenticated) {
          // Reset flags for next login
          if (_hasChecked || _isChecking || _trackingStarted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasChecked = false;
                  _isChecking = false;
                  _trackingStarted = false;
                });
              }
            });
          }
          // Stop inactivity tracking when logged out
          inactivity.stopTracking();
          return const LoginScreen();
        }

        // Check if locked (only when authenticated)
        if (inactivity.isLocked) {
          return LockScreen(
            onUnlock: () {
              inactivity.unlock();
            },
          );
        }

        // Start inactivity tracking when authenticated (only once)
        if (!_trackingStarted && !inactivity.isLocked) {
          _trackingStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('🔒 Starting inactivity tracking...');
            inactivity.startTracking();
            // Load currency settings from backend
            _loadCurrencySettings();
          });
        }

        // ✅ Authenticated - need to check session
        if (!_hasChecked && !_isChecking) {
          debugPrint('🟡 Need to check session');
          // Schedule check AFTER build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _performSessionCheck();
            }
          });

          // Set checking flag immediately (but after build)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isChecking) {
              setState(() => _isChecking = true);
            }
          });

          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking for existing session...'),
                ],
              ),
            ),
          );
        }

        // Still checking
        if (_isChecking) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking for existing session...'),
                ],
              ),
            ),
          );
        }

        // Has session - show dashboard
        if (session.hasActiveSession) {
          debugPrint('→ Dashboard');
          return const DashboardScreen();
        }

        // No session - show register selection
        debugPrint('→ Register Selection');
        return const RegisterSelectionScreen();
      },
    );
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final apiService = context.read<ApiService>();
      final currencyProvider = context.read<CurrencyProvider>();
      await currencyProvider.loadSettings(apiService);
    } catch (e) {
      debugPrint('❌ Error loading currency settings: $e');
    }
  }

  Future<void> _performSessionCheck() async {
    debugPrint('🔍 Starting session check...');

    final auth = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    try {
      await sessionProvider.checkActiveSession();

      if (!mounted) return;

      final activeSession = sessionProvider.activeSession;
      final currentUserId = auth.user?.id;

      debugPrint('📊 Session check result:');
      debugPrint('   activeSession: ${activeSession != null}');
      debugPrint(
          '   user_id match: ${activeSession?['user_id'] == currentUserId}');
      debugPrint('   session user_id: ${activeSession?['user_id']}');
      debugPrint('   current user_id: $currentUserId');

      // Has existing session for this user
      if (activeSession != null && activeSession['user_id'] == currentUserId) {
        debugPrint('✅ Showing existing session dialog');

        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExistingSessionDialog(session: activeSession),
        );

        if (!mounted) return;

        debugPrint('Dialog result: $result');

        if (result == 'continue') {
          // Continue with session - it's already set
        } else if (result == 'start_fresh') {
          // Session was closed and logged out
        } else {
          // Cancelled
          await auth.logout();
        }
      } else {
        debugPrint('📝 No existing session');
      }
    } catch (e) {
      debugPrint('❌ Session check error: $e');
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _hasChecked = true;
      });
    }
  }
}
