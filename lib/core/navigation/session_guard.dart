import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/session/session_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/session/existing_session_dialog.dart';

/// Session Guard Widget - CLEAN VERSION
///
/// Simple rule:
/// - If user is authenticated AND no session → redirect to register selection
/// - If user is NOT authenticated → do nothing (login screen will show)
class SessionGuard extends StatefulWidget {
  final Widget child;

  const SessionGuard({
    super.key,
    required this.child,
  });

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  bool _isChecking = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final sessionProvider = context.read<SessionProvider>();
    final authProvider = context.read<AuthProvider>();

    // Check for active session
    await sessionProvider.checkActiveSession();

    final activeSession = sessionProvider.activeSession;
    final currentUserId = authProvider.user?.id;

    if (!mounted) return;

    // CASE 1: User has their own open session
    if (activeSession != null && activeSession['user_id'] == currentUserId) {
      debugPrint('✅ SessionGuard: Found existing session');

      // Show "Continue or Start Fresh" dialog
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExistingSessionDialog(session: activeSession),
      );

      if (!mounted) return;

      if (result == 'continue') {
        debugPrint('✅ SessionGuard: Continuing session');
        setState(() {
          _hasSession = true;
          _isChecking = false;
        });
        return;
      } else if (result == 'start_fresh') {
        debugPrint('🔄 SessionGuard: Session closed, user logged out');
        return;
      } else {
        debugPrint('❌ SessionGuard: User cancelled');
        await authProvider.logout();
        return;
      }
    }

    // CASE 2: No active session - redirect to register selection
    if (activeSession == null) {
      debugPrint(
          '📝 SessionGuard: No session, redirecting to register selection');
      setState(() {
        _hasSession = false;
        _isChecking = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/register-selection');
        }
      });
      return;
    }

    setState(() {
      _hasSession = false;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasSession) {
      return const Scaffold(
        body: Center(
          child: Text('Redirecting...'),
        ),
      );
    }

    // ✅ HAS SESSION - Watch for changes but DON'T redirect if user is logging out
    return Consumer2<SessionProvider, AuthProvider>(
      builder: (context, sessionProvider, authProvider, _) {
        // If user is NOT authenticated anymore, just show loading (logout will handle navigation)
        if (!authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If session closed but user IS authenticated, redirect to register selection
        if (!sessionProvider.hasActiveSession) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && authProvider.isAuthenticated) {
              Navigator.of(context).pushReplacementNamed('/register-selection');
            }
          });

          return const Scaffold(
            body: Center(
              child: Text('Session closed. Redirecting...'),
            ),
          );
        }

        // ✅ Has session AND authenticated - show content
        return widget.child;
      },
    );
  }
}
