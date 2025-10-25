import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../session/session_provider.dart';
import '../sales/sales_screen.dart';
import '../session/register_selection_screen.dart';
import '../session/existing_session_dialog.dart';
import '../session/session_screen.dart';
import '../reports/reports_screen.dart';
import '../../core/services/connectivity_provider.dart';
import '../../shared/constants/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// ✅ SMART SESSION HANDLING
  /// Checks if user has existing session and shows appropriate dialog
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
      // Show "Continue or Start Fresh" dialog
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExistingSessionDialog(session: activeSession),
      );

      if (result == 'continue') {
        // User chose to continue - stay on dashboard
        debugPrint('✅ Continuing existing session');
        return;
      } else if (result == 'start_fresh') {
        // User closed session and wants to start fresh
        // Show register selection
        debugPrint('🔄 Starting fresh session');
        if (mounted) {
          _showRegisterSelection();
        }
      } else {
        // User cancelled - logout
        debugPrint('❌ User cancelled - logging out');
        if (mounted) {
          final auth = context.read<AuthProvider>();
          await auth.logout();
        }
      }
      return;
    }

    // CASE 2: No active session - show register selection
    if (activeSession == null) {
      debugPrint('📝 No active session, showing register selection');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRegisterSelection();
      });
    }
  }

  void _showRegisterSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterSelectionScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleLogout() async {
    final sessionProvider = context.read<SessionProvider>();

    // Check if session is open
    if (sessionProvider.hasActiveSession) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Close Session?'),
          content: const Text(
            'You have an active session. Please close your session before logging out.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
                setState(() {
                  _selectedIndex = 2; // Go to session screen
                });
              },
              child: const Text('Close Session'),
            ),
          ],
        ),
      );
      return;
    }

    // Logout
    final auth = context.read<AuthProvider>();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const SalesScreen(),
      const SalesScreen(), // Dashboard (using sales for now)
      const SessionScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Left Navigation Menu
          Container(
            width: 80,
            color: AppColors.primary,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo
                Icon(
                  Icons.point_of_sale_rounded,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 40),

                // Menu Items
                _buildMenuItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _buildMenuItem(Icons.shopping_cart_rounded, 'Sale', 1),
                _buildMenuItem(Icons.schedule_rounded, 'Session', 2),
                _buildMenuItem(Icons.bar_chart_rounded, 'Reports', 3),

                const Spacer(),

                // Online/Offline Indicator
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, _) {
                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: connectivity.isOnline
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        connectivity.isOnline
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: connectivity.isOnline
                            ? AppColors.success
                            : AppColors.error,
                        size: 20,
                      ),
                    );
                  },
                ),

                // Logout Button
                InkWell(
                  onTap: _handleLogout,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),

                      // User Info
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.user?.name ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    auth.user?.storeName ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Offline Banner
                Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, _) {
                    if (connectivity.isOnline) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: AppColors.warning.withOpacity(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Working Offline - Changes will sync when online',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Content
                Expanded(
                  child: screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
