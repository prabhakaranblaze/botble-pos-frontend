import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';
import '../../shared/constants/app_constants.dart';
import '../../core/services/thermal_print_service.dart';
import '../../core/services/update_service.dart';
import '../../core/providers/update_provider.dart';
import '../../core/database/database_service.dart';
import '../../core/database/saved_cart_database.dart';
import '../auth/auth_provider.dart';
import '../sales/sales_provider.dart';
import '../../core/models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final hasSettingsPermission = user?.hasPermission(PosPermissions.posSettings) ??
                                   user?.isSuperUser ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Two column layout: Printer Settings | Receipt Preview
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Printer Settings
                Expanded(
                  flex: 3,
                  child: _buildSection(
                    title: 'Printer Settings',
                    icon: Icons.print,
                    child: const PrinterSettingsCard(),
                  ),
                ),
                const SizedBox(width: 24),
                // Right column - Receipt Preview
                Expanded(
                  flex: 2,
                  child: _buildSection(
                    title: 'Receipt Preview',
                    icon: Icons.receipt_long,
                    child: const ReceiptPreviewCard(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Two column layout: Data Management | Updates & About
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data Management
                Expanded(
                  child: _buildSection(
                    title: 'Data Management',
                    icon: Icons.storage,
                    child: _buildDataManagementCard(),
                  ),
                ),
                const SizedBox(width: 24),
                // Updates & App Info
                Expanded(
                  child: Column(
                    children: [
                      _buildUpdateSection(),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'About',
                        icon: Icons.info_outline,
                        child: _buildAboutCard(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildUpdateSection() {
    return Consumer<UpdateProvider>(
      builder: (context, updateProvider, child) {
        final hasUpdate = updateProvider.hasUpdate;
        final updateInfo = updateProvider.updateInfo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Software Update',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasUpdate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current version info
                    Row(
                      children: [
                        Icon(
                          hasUpdate ? Icons.update : Icons.check_circle,
                          color: hasUpdate ? AppColors.warning : AppColors.success,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasUpdate ? 'Update Available' : 'App is up to date',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Current: v${UpdateService.appVersion}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              if (hasUpdate && updateInfo != null)
                                Text(
                                  'Latest: v${updateInfo.latestVersion}',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Check/Download button
                        if (updateProvider.isChecking)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (updateProvider.isDownloading)
                          Column(
                            children: [
                              SizedBox(
                                width: 80,
                                child: LinearProgressIndicator(
                                  value: updateProvider.downloadProgress,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(updateProvider.downloadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          )
                        else if (hasUpdate)
                          ElevatedButton.icon(
                            onPressed: () => _downloadAndInstallUpdate(updateProvider),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Update'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => updateProvider.checkForUpdate(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Check'),
                          ),
                      ],
                    ),

                    // Release notes
                    if (hasUpdate && updateInfo != null && updateInfo.releaseNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'What\'s New:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...updateInfo.releaseNotes.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (updateInfo.fileSize != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Download size: ${updateInfo.fileSize}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndInstallUpdate(UpdateProvider updateProvider) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Install Update'),
          ],
        ),
        content: Text(
          'Download and install version ${updateProvider.updateInfo?.latestVersion}?\n\n'
          'The app will restart after installation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Download update
    final success = await updateProvider.downloadUpdate();

    if (success && mounted) {
      // Install update
      await updateProvider.installUpdate();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateProvider.error ?? 'Download failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('App Name', AppConstants.appName),
            const Divider(),
            _buildInfoRow('Version', UpdateService.appVersion),
            const Divider(),
            _buildInfoRow('Currency', AppConstants.currencyCode),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clear & Resync Products
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sync, color: AppColors.warning),
              ),
              title: const Text(
                'Clear & Resync Products',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Clear local product cache and download fresh data from server',
                style: TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () => _showClearAndResyncDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Resync'),
              ),
            ),

            const Divider(height: 24),

            // Clear All Local Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_forever, color: AppColors.error),
              ),
              title: const Text(
                'Clear All Local Data',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Remove all cached data including products, saved carts, and pending orders',
                style: TextStyle(fontSize: 12),
              ),
              trailing: OutlinedButton(
                onPressed: () => _showClearAllDataDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearAndResyncDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sync, color: AppColors.warning),
            const SizedBox(width: 12),
            const Text('Clear & Resync Products'),
          ],
        ),
        content: const Text(
          'This will:\n'
          '• Delete all locally cached products\n'
          '• Download fresh product data from server\n'
          '• Update product images and prices\n\n'
          'Your saved carts and pending orders will NOT be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resync Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performResync();
    }
  }

  Future<void> _performResync() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Resyncing products...'),
          ],
        ),
      ),
    );

    try {
      final db = DatabaseService();
      final salesProvider = context.read<SalesProvider>();

      // Clear products table
      final database = await db.database;
      await database.delete('products');
      debugPrint('🗑️ RESYNC: Products table cleared');

      // Reload products from API
      await salesProvider.loadProducts(refresh: true);
      debugPrint('✅ RESYNC: Products reloaded from API');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Products resynced successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ RESYNC: Error - $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resync failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showClearAllDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Clear All Data'),
          ],
        ),
        content: const Text(
          '⚠️ WARNING: This will permanently delete:\n\n'
          '• All cached products\n'
          '• All saved/held carts\n'
          '• All pending offline orders\n'
          '• Session history\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performClearAll();
    }
  }

  Future<void> _performClearAll() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Clearing all data...'),
          ],
        ),
      ),
    );

    try {
      final db = DatabaseService();
      final savedCartDb = SavedCartDatabase();
      final salesProvider = context.read<SalesProvider>();

      // Clear all tables
      await db.clearAllData();
      await savedCartDb.clearAll();
      debugPrint('🗑️ CLEAR ALL: All local data cleared');

      // Reload fresh data
      await salesProvider.loadProducts(refresh: true);
      debugPrint('✅ CLEAR ALL: Fresh data loaded');

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local data cleared and resynced!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ CLEAR ALL: Error - $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clear failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Printer Settings Card
class PrinterSettingsCard extends StatefulWidget {
  const PrinterSettingsCard({super.key});

  @override
  State<PrinterSettingsCard> createState() => _PrinterSettingsCardState();
}

class _PrinterSettingsCardState extends State<PrinterSettingsCard> {
  static const String _printerNameKey = 'default_printer_name';
  static const String _printerAddressKey = 'default_printer_address';
  static const String _printerConnectionTypeKey = 'default_printer_connection_type';
  static const String _autoPrintKey = 'auto_print_enabled';

  final ThermalPrintService _printService = ThermalPrintService();

  String? _savedPrinterName;
  String? _savedPrinterAddress;
  bool _autoPrintEnabled = true;
  bool _isScanning = false;
  bool _isTesting = false;
  List<Printer> _availablePrinters = [];
  ConnectionType _selectedConnectionType = ConnectionType.USB;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    // Don't auto-scan - only scan when user clicks "Scan" button
  }

  @override
  void dispose() {
    // Stop scanning when leaving settings page
    _printService.stopScan();
    super.dispose();
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure we get fresh data

    final savedAutoPrint = prefs.getBool(_autoPrintKey);
    debugPrint('🔧 SETTINGS: Loading auto-print: $savedAutoPrint (raw), using: ${savedAutoPrint ?? true}');
    debugPrint('🔧 SETTINGS: Loading printer: ${prefs.getString(_printerNameKey)}');

    setState(() {
      _savedPrinterName = prefs.getString(_printerNameKey);
      _savedPrinterAddress = prefs.getString(_printerAddressKey);
      _autoPrintEnabled = savedAutoPrint ?? true;
    });
  }

  Future<void> _savePrinter(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerNameKey, printer.name ?? 'Unknown');
    await prefs.setString(_printerAddressKey, printer.address ?? '');
    await prefs.setString(_printerConnectionTypeKey, printer.connectionType?.name ?? 'USB');

    debugPrint('🔧 SETTINGS: Saved printer: ${printer.name} (${printer.address})');

    setState(() {
      _savedPrinterName = printer.name;
      _savedPrinterAddress = printer.address;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default printer set to: ${printer.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _toggleAutoPrint(bool value) async {
    debugPrint('🔧 SETTINGS: Toggling auto-print to: $value');

    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setBool(_autoPrintKey, value);
    debugPrint('🔧 SETTINGS: setBool result: $success');

    // Verify it was saved
    await prefs.reload();
    final savedValue = prefs.getBool(_autoPrintKey);
    debugPrint('🔧 SETTINGS: Verified saved auto-print: $savedValue');

    setState(() {
      _autoPrintEnabled = value;
    });
  }

  Future<void> _clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printerNameKey);
    await prefs.remove(_printerAddressKey);
    await prefs.remove(_printerConnectionTypeKey);

    setState(() {
      _savedPrinterName = null;
      _savedPrinterAddress = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default printer cleared')),
      );
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _availablePrinters = [];
    });

    _printService.startScan(
      connectionTypes: [_selectedConnectionType],
    );

    // Update printer list after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _availablePrinters = _filterVirtualPrinters(_printService.availablePrinters);
        });
      }
    });

    // Keep scanning for a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _availablePrinters = _filterVirtualPrinters(_printService.availablePrinters);
          _isScanning = false;
        });
      }
    });
  }

  /// Filter out virtual printers (PDF, OneNote, Fax, etc.)
  List<Printer> _filterVirtualPrinters(List<Printer> printers) {
    final virtualKeywords = [
      'pdf', 'onenote', 'fax', 'xps', 'microsoft', 'virtual',
      'adobe', 'print to', 'document', 'send to'
    ];

    return printers.where((printer) {
      final name = (printer.name ?? '').toLowerCase();
      // Keep printer if it doesn't contain any virtual printer keywords
      return !virtualKeywords.any((keyword) => name.contains(keyword));
    }).toList();
  }

  Future<void> _testPrint() async {
    if (_savedPrinterAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a printer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTesting = true);

    try {
      // Find the saved printer in available printers
      await _printService.startScan(connectionTypes: [ConnectionType.USB, ConnectionType.BLE, ConnectionType.NETWORK]);
      await Future.delayed(const Duration(seconds: 2));

      final printers = _printService.availablePrinters;
      final savedPrinter = printers.firstWhere(
        (p) => p.address == _savedPrinterAddress,
        orElse: () => printers.first,
      );

      _printService.selectPrinter(savedPrinter);

      // Build test receipt
      final testData = _buildTestReceipt();

      final connected = await _printService.connect();
      if (connected) {
        await FlutterThermalPrinter.instance.printData(
          savedPrinter,
          testData,
          longData: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test print sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Could not connect to printer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isTesting = false);
  }

  List<int> _buildTestReceipt() {
    final List<int> commands = [];

    // Initialize
    commands.addAll([0x1B, 0x40]);

    // Center align
    commands.addAll([0x1B, 0x61, 0x01]);

    // Bold on + double height
    commands.addAll([0x1B, 0x45, 0x01]);
    commands.addAll([0x1D, 0x21, 0x10]);

    commands.addAll('TEST PRINT'.codeUnits);
    commands.add(0x0A);

    // Normal size
    commands.addAll([0x1D, 0x21, 0x00]);
    commands.addAll([0x1B, 0x45, 0x00]);

    commands.addAll('--------------------------------'.codeUnits);
    commands.add(0x0A);

    commands.addAll(AppConstants.appName.codeUnits);
    commands.add(0x0A);

    commands.addAll('Printer: ${_savedPrinterName ?? "Unknown"}'.codeUnits);
    commands.add(0x0A);

    commands.addAll('--------------------------------'.codeUnits);
    commands.add(0x0A);

    commands.addAll('If you can see this,'.codeUnits);
    commands.add(0x0A);
    commands.addAll('your printer is working!'.codeUnits);
    commands.add(0x0A);
    commands.add(0x0A);

    // Feed and cut
    commands.addAll([0x1B, 0x64, 0x04]);
    commands.addAll([0x1D, 0x56, 0x00]);

    return commands;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Printer
            Row(
              children: [
                Icon(
                  _savedPrinterName != null ? Icons.print : Icons.print_disabled,
                  color: _savedPrinterName != null ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Default Printer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _savedPrinterName ?? 'Not configured',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _savedPrinterName != null ? null : AppColors.textSecondary,
                        ),
                      ),
                      if (_savedPrinterAddress != null)
                        Text(
                          _savedPrinterAddress!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (_savedPrinterName != null) ...[
                  IconButton(
                    icon: _isTesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print),
                    onPressed: _isTesting ? null : _testPrint,
                    tooltip: 'Test Print',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearPrinter,
                    tooltip: 'Clear',
                  ),
                ],
              ],
            ),

            const Divider(height: 24),

            // Auto Print Toggle
            SwitchListTile(
              title: const Text('Auto Print on Payment'),
              subtitle: const Text('Automatically print receipt when order is paid'),
              value: _autoPrintEnabled,
              onChanged: _toggleAutoPrint,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 24),

            // Scan for Printers
            Row(
              children: [
                const Text(
                  'Select Printer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                SegmentedButton<ConnectionType>(
                  segments: const [
                    ButtonSegment(
                      value: ConnectionType.USB,
                      label: Text('USB'),
                    ),
                    ButtonSegment(
                      value: ConnectionType.BLE,
                      label: Text('BT'),
                    ),
                    ButtonSegment(
                      value: ConnectionType.NETWORK,
                      label: Text('WiFi'),
                    ),
                  ],
                  selected: {_selectedConnectionType},
                  onSelectionChanged: (types) {
                    setState(() {
                      _selectedConnectionType = types.first;
                    });
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Note about thermal printers
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Requires ESC/POS thermal receipt printer (Epson, Star, HOIN, etc.)\nVirtual printers (PDF, OneNote) are not supported.',
                      style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),

            // Printer List
            if (_availablePrinters.isEmpty && !_isScanning)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.print_disabled,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No thermal printers found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect a USB thermal printer and click Scan',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availablePrinters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final printer = _availablePrinters[index];
                    final isSelected = printer.address == _savedPrinterAddress;

                    return ListTile(
                      leading: Icon(
                        _getConnectionIcon(printer.connectionType),
                        color: isSelected ? AppColors.success : AppColors.primary,
                      ),
                      title: Text(printer.name ?? 'Unknown Printer'),
                      subtitle: Text(
                        printer.address ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppColors.success)
                          : const Icon(Icons.chevron_right),
                      selected: isSelected,
                      onTap: () => _savePrinter(printer),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getConnectionIcon(ConnectionType? type) {
    switch (type) {
      case ConnectionType.USB:
        return Icons.usb;
      case ConnectionType.BLE:
        return Icons.bluetooth;
      case ConnectionType.NETWORK:
        return Icons.wifi;
      default:
        return Icons.print;
    }
  }
}

/// Receipt Preview Card - Shows thermal receipt with demo data
class ReceiptPreviewCard extends StatefulWidget {
  const ReceiptPreviewCard({super.key});

  @override
  State<ReceiptPreviewCard> createState() => _ReceiptPreviewCardState();
}

class _ReceiptPreviewCardState extends State<ReceiptPreviewCard> {
  String _paymentType = 'cash'; // 'cash' or 'card'

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment type toggle
            Row(
              children: [
                const Text('Demo Payment: ', style: TextStyle(fontSize: 12)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'cash', label: Text('Cash')),
                    ButtonSegment(value: 'card', label: Text('Card')),
                  ],
                  selected: {_paymentType},
                  onSelectionChanged: (types) {
                    setState(() => _paymentType = types.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Receipt preview (thermal paper style)
            Center(
              child: Container(
                width: 280, // 58mm paper width at ~screen DPI
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildReceiptContent(),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                '58mm Thermal Paper Preview',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();
    final isCash = _paymentType == 'cash';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 11,
          color: Colors.black,
          height: 1.3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Text('POS Receipt'),
            const SizedBox(height: 8),

            // Order info
            _receiptLine('Order: #ORD-00123'),
            _receiptLine('Date: ${dateFormat.format(now)}'),
            _receiptLine('Customer: John Doe'),
            _receiptLine(isCash ? 'Payment: Cash' : 'Payment: Card (*4242)'),

            const SizedBox(height: 4),
            _divider(),
            const SizedBox(height: 4),

            // Column headers
            _itemRow('Item', 'Qty', 'Amount', bold: true),
            _divider(),
            const SizedBox(height: 2),

            // Demo items
            _itemRow('Organic Coffee Beans', '2', '${AppConstants.currencyCode} 45.00'),
            _itemRow('Fresh Milk 1L', '1', '${AppConstants.currencyCode} 12.50'),
            _itemRow('Whole Wheat Bread', '1', '${AppConstants.currencyCode} 8.00'),

            const SizedBox(height: 4),
            _divider(),
            const SizedBox(height: 4),

            // Totals
            _totalRow('Subtotal:', '${AppConstants.currencyCode} 65.50'),
            _totalRow('Tax (15%):', '${AppConstants.currencyCode} 9.83'),
            _totalRow('Discount:', '-${AppConstants.currencyCode} 5.00'),

            _divider(),

            // Grand total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '${AppConstants.currencyCode} 70.33',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Cash payment details
            if (isCash) ...[
              const SizedBox(height: 2),
              _totalRow('Cash:', '${AppConstants.currencyCode} 100.00'),
              _totalRow('Change:', '${AppConstants.currencyCode} 29.67'),
            ],

            const SizedBox(height: 8),
            _divider(),
            const SizedBox(height: 8),

            // Footer
            const Text(
              'Thank you for your purchase!',
              textAlign: TextAlign.center,
            ),
            const Text(
              'Please come again',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _receiptLine(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }

  Widget _divider() {
    return const Text(
      '--------------------------------',
      style: TextStyle(letterSpacing: -1),
    );
  }

  Widget _itemRow(String name, String qty, String amount, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    // Truncate long names
    final displayName = name.length > 18 ? '${name.substring(0, 18)}' : name;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(displayName, style: style),
        ),
        SizedBox(
          width: 30,
          child: Text(qty, textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          flex: 3,
          child: Text(amount, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(amount),
        ],
      ),
    );
  }
}
