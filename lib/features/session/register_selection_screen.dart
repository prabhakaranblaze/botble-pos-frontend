import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'session_provider.dart';
import 'open_session_dialog.dart';
import '../auth/auth_provider.dart';
import '../../shared/constants/app_constants.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRegisters();
      }
    });
  }

  Future<void> _loadRegisters() async {
    await context.read<SessionProvider>().loadCashRegisters();
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

  Future<void> _selectRegister(dynamic register) async {
    // ✅ CHECK: Is this register occupied?
    if (register['has_active_session'] == true) {
      // Show error - register is occupied
      final activeSession = register['active_session'];

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: AppColors.error),
              const SizedBox(width: 12),
              const Text('Register Not Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This register is currently in use',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'User: ${activeSession['user_name'] ?? 'Unknown'}',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Since: ${_formatDateTime(activeSession['opened_at'])}',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${activeSession['duration_hours']}h ${activeSession['duration_minutes']}m',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ Only ${activeSession['user_name'] ?? 'the owner'} can close this session.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select another register or wait for this session to be closed.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Select Another Register'),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ Register is available - proceed to open session
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OpenSessionDialog(registerId: register['id']),
    );

    // ✅ DON'T NAVIGATE MANUALLY
    // After opening session, sessionProvider.activeSession will be set
    // AuthWrapper will automatically detect this and show the dashboard
    // No need to call Navigator.pop() or Navigator.pushNamed()

    if (result == true) {
      debugPrint(
          '✅ Session opened successfully, AuthWrapper will navigate automatically');
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cash Register'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, _) {
          if (session.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (session.registers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.point_of_sale_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cash registers available',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadRegisters,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: session.registers.length,
            itemBuilder: (context, index) {
              final register = session.registers[index];
              final isOccupied = register['has_active_session'] == true;
              final activeSession = register['active_session'];

              return Card(
                elevation: isOccupied ? 1 : 2,
                color: isOccupied ? AppColors.background : AppColors.surface,
                child: InkWell(
                  onTap: () => _selectRegister(register),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with status indicator
                        Stack(
                          children: [
                            Icon(
                              Icons.point_of_sale_rounded,
                              size: 48,
                              color: isOccupied
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                            // Status dot
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isOccupied
                                      ? AppColors.error
                                      : AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Register name
                        Text(
                          register['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOccupied
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        // Register code
                        Text(
                          register['code'],
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ✅ Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isOccupied
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOccupied
                                  ? AppColors.error.withOpacity(0.3)
                                  : AppColors.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOccupied
                                    ? Icons.lock_outline
                                    : Icons.check_circle_outline,
                                size: 14,
                                color: isOccupied
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOccupied ? 'IN USE' : 'AVAILABLE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOccupied
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Show user info if occupied
                        if (isOccupied && activeSession != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            activeSession['user_name'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${activeSession['duration_hours']}h ${activeSession['duration_minutes']}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],

                        // ✅ Description if available and not occupied
                        if (!isOccupied &&
                            register['description'] != null &&
                            register['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            register['description'],
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
