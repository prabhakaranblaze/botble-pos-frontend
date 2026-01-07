import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';
import 'open_session_dialog.dart';
import '../auth/auth_provider.dart';
import '../../shared/constants/app_constants.dart';

/// Open Register Screen
///
/// Simplified screen that allows user to open a register/session
/// No register selection needed - just enter opening cash and go
class RegisterSelectionScreen extends StatefulWidget {
  const RegisterSelectionScreen({super.key});

  @override
  State<RegisterSelectionScreen> createState() =>
      _RegisterSelectionScreenState();
}

class _RegisterSelectionScreenState extends State<RegisterSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Show open session dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showOpenSessionDialog();
      }
    });
  }

  Future<void> _showOpenSessionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OpenSessionDialog(),
    );

    if (result == true) {
      debugPrint(
          '✅ Session opened successfully, AuthWrapper will navigate automatically');
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Clear session data
      context.read<SessionProvider>().clearSession();
      // Logout
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Register'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.point_of_sale_rounded,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, $userName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a register to start your session',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showOpenSessionDialog,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Open Register'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
