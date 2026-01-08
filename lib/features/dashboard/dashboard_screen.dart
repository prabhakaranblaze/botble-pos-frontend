import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../auth/auth_provider.dart';
import '../session/session_provider.dart';
import '../sales/sales_screen.dart';
import '../session/session_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/services/connectivity_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/pos_mode_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/constants/app_constants.dart';
import '../sales/saved_carts_screen.dart';
import 'recent_bills_dialog.dart';

/// Dashboard Screen - Main application screen
///
/// SessionGuard ensures user has active session before accessing this screen
/// No need for manual session checking here!
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  bool _isFullScreen = false;
  bool _windowManagerReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _startClock();
    _initWindowManager();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  Future<void> _initWindowManager() async {
    try {
      // Window manager is already initialized in main.dart
      _windowManagerReady = true;
      _isFullScreen = await windowManager.isFullScreen();
      if (mounted) setState(() {});
      debugPrint('🖥️ Window ready, fullscreen: $_isFullScreen');
    } catch (e) {
      debugPrint('🖥️ Window manager check error: $e');
      _windowManagerReady = false;
    }
  }

  Future<void> _toggleFullScreen() async {
    try {
      _isFullScreen = !_isFullScreen;
      debugPrint('🖥️ Setting fullscreen to: $_isFullScreen');

      // setFullScreen hides Windows taskbar and title bar (true kiosk mode)
      await windowManager.setFullScreen(_isFullScreen);

      // Wait for window to settle, then regain focus (fixes input not working after toggle)
      await Future.delayed(const Duration(milliseconds: 150));
      await windowManager.focus();

      setState(() {});
      debugPrint('🖥️ Fullscreen: $_isFullScreen');
    } catch (e) {
      debugPrint('🖥️ Toggle fullscreen error: $e');
      // Revert state on error
      _isFullScreen = !_isFullScreen;
      setState(() {});
    }
  }

  void _showCalculator() {
    showDialog(
      context: context,
      builder: (context) => const CalculatorDialog(),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    final sessionProvider = context.read<SessionProvider>();

    // Check if session is open
    if (sessionProvider.hasActiveSession) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Close Session First'),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Go to Session'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        // Navigate to session tab (index 1)
        _tabController.animateTo(2);
      }
      return;
    }

    // No active session - safe to logout
    final auth = context.read<AuthProvider>();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Row(
          children: [
            // Left Navigation Menu
            Container(
              width: 80,
              color: AppColors.primary,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Logo
                  const Icon(
                    Icons.point_of_sale_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),

                  // Scrollable Menu Items
                  Expanded(
                    child: SingleChildScrollView(
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Column(
                            children: [
                              _buildMenuItem(Icons.shopping_cart_rounded, l10n?.sales ?? 'Sale', 0),
                              _buildMenuItem(Icons.bookmark_rounded, l10n?.savedCarts ?? 'Saved', 1),
                              _buildMenuItem(Icons.schedule_rounded, l10n?.session ?? 'Session', 2),
                              _buildMenuItem(Icons.bar_chart_rounded, l10n?.reports ?? 'Reports', 3),
                              _buildMenuItem(Icons.settings_rounded, l10n?.settings ?? 'Settings', 4),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Online/Offline Indicator
                  Consumer<ConnectivityProvider>(
                    builder: (context, connectivity, _) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
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
                          size: 18,
                        ),
                      );
                    },
                  ),

                  // Logout Button
                  InkWell(
                    onTap: _handleLogout,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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

                        // POS Mode Toggle
                        Consumer<PosModeProvider>(
                          builder: (context, modeProvider, _) {
                            return Tooltip(
                              message: 'Switch to ${modeProvider.isQuickSelect ? 'Kiosk' : 'Quick Select'} mode',
                              child: InkWell(
                                onTap: () => modeProvider.toggleMode(),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: modeProvider.isKiosk
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: modeProvider.isKiosk
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        modeProvider.modeIcon,
                                        size: 18,
                                        color: modeProvider.isKiosk
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        modeProvider.modeName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: modeProvider.isKiosk
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Clock
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(_currentTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Currency
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppConstants.currencyCode,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Language Selector
                        Consumer<LocaleProvider>(
                          builder: (context, localeProvider, _) {
                            return PopupMenuButton<Locale>(
                              tooltip: 'Change Language',
                              offset: const Offset(0, 40),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _getFlag(localeProvider.locale),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      localeProvider.locale.languageCode
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down,
                                        color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) =>
                                  LocaleProvider.supportedLocales.map((locale) {
                                return PopupMenuItem<Locale>(
                                  value: locale,
                                  child: Row(
                                    children: [
                                      Text(_getFlag(locale),
                                          style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text(localeProvider.getDisplayName(locale)),
                                      if (locale == localeProvider.locale)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Icon(Icons.check,
                                              color: AppColors.success,
                                              size: 18),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onSelected: (locale) {
                                localeProvider.setLocale(locale);
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Recent Bills Button
                        IconButton(
                          icon: const Icon(Icons.receipt_long_outlined),
                          tooltip: 'Recent Bills',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const RecentBillsDialog(),
                            );
                          },
                        ),

                        // Calculator Button
                        IconButton(
                          icon: const Icon(Icons.calculate_outlined),
                          tooltip: 'Calculator',
                          onPressed: _showCalculator,
                        ),

                        // Full Screen Button
                        IconButton(
                          icon: Icon(_isFullScreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen),
                          tooltip:
                              _isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                          onPressed: _toggleFullScreen,
                        ),
                        const SizedBox(width: 12),

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
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const SalesScreen(), // Index 0 - Sale
                        SavedCartsScreen(
                          onCartLoaded: () {
                            debugPrint('🔄 DASHBOARD: Switching to Sale tab');
                            _tabController.animateTo(0);
                          },
                        ), // Index 1 - Saved Cart
                        const SessionScreen(), // Index 2 - Session
                        const ReportsScreen(), // Index 3 - Reports
                        const SettingsScreen(), // Index 4 - Settings
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isSelected = _tabController.index == index;

        return Tooltip(
          message: label,
          child: InkWell(
            onTap: () {
              _tabController.animateTo(index);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
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
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _getFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }
}

/// Simple Calculator Dialog
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _operand1 = '';
  String _operator = '';
  bool _shouldResetDisplay = false;

  void _onDigit(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _operand1 = _display;
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onEquals() {
    if (_operand1.isEmpty || _operator.isEmpty) return;

    final num1 = double.tryParse(_operand1) ?? 0;
    final num2 = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = num1 + num2;
        break;
      case '-':
        result = num1 - num2;
        break;
      case '×':
        result = num1 * num2;
        break;
      case '÷':
        result = num2 != 0 ? num1 / num2 : 0;
        break;
    }

    setState(() {
      _display = result == result.truncate()
          ? result.truncate().toString()
          : result.toStringAsFixed(2);
      _operand1 = '';
      _operator = '';
      _shouldResetDisplay = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _operand1 = '';
      _operator = '';
      _shouldResetDisplay = false;
    });
  }

  void _onDecimal() {
    setState(() {
      if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Calculator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_operand1.isNotEmpty)
                    Text(
                      '$_operand1 $_operator',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            _buildButtonRow(['C', '⌫', '%', '÷']),
            _buildButtonRow(['7', '8', '9', '×']),
            _buildButtonRow(['4', '5', '6', '-']),
            _buildButtonRow(['1', '2', '3', '+']),
            _buildButtonRow(['00', '0', '.', '=']),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: buttons.map((btn) {
          final isOperator = ['+', '-', '×', '÷', '='].contains(btn);
          final isSpecial = ['C', '⌫', '%'].contains(btn);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOperator
                      ? AppColors.primary
                      : isSpecial
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.surface,
                  foregroundColor: isOperator
                      ? Colors.white
                      : isSpecial
                          ? AppColors.error
                          : AppColors.textPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isOperator ? Colors.transparent : AppColors.border,
                    ),
                  ),
                ),
                onPressed: () => _handleButton(btn),
                child: Text(
                  btn,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleButton(String btn) {
    switch (btn) {
      case 'C':
        _onClear();
        break;
      case '⌫':
        _onBackspace();
        break;
      case '%':
        setState(() {
          final value = double.tryParse(_display) ?? 0;
          _display = (value / 100).toString();
        });
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        _onOperator(btn);
        break;
      case '=':
        _onEquals();
        break;
      case '.':
        _onDecimal();
        break;
      default:
        _onDigit(btn);
    }
  }
}
