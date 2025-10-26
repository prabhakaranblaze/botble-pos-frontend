import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/database/database_service.dart';
import 'core/api/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/audio_service.dart';
import 'core/services/connectivity_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/sales/sales_provider.dart';
import 'features/session/session_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/session/register_selection_screen.dart';
import 'features/session/existing_session_dialog.dart';
import 'shared/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final databaseService = DatabaseService();
  final apiService = ApiService(databaseService, storageService);
  final audioService = AudioService();
  await audioService.preload(); // preload beep sound for instant playback
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(
            create: (_) => AuthProvider(apiService, storageService)),
        ChangeNotifierProvider(
            create: (_) => SalesProvider(apiService, audioService)),
        ChangeNotifierProvider(
            create: (_) => SessionProvider(apiService, storageService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SessionProvider>(
      builder: (context, auth, session, child) {
        debugPrint(
            '🔵 AuthWrapper: auth=${auth.isAuthenticated}, session=${session.hasActiveSession}, checking=$_isChecking, checked=$_hasChecked');

        // NOT authenticated
        if (!auth.isAuthenticated) {
          // Reset flags for next login
          if (_hasChecked || _isChecking) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasChecked = false;
                  _isChecking = false;
                });
              }
            });
          }
          return const LoginScreen();
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
