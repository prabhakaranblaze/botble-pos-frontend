import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../../shared/constants/app_constants.dart';
import '../../core/services/thermal_print_service.dart';
import '../auth/auth_provider.dart';
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

            // Printer Settings
            _buildSection(
              title: 'Printer Settings',
              icon: Icons.print,
              child: const PrinterSettingsCard(),
            ),

            const SizedBox(height: 24),

            // App Info
            _buildSection(
              title: 'About',
              icon: Icons.info_outline,
              child: _buildAboutCard(),
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

  Widget _buildAboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('App Name', AppConstants.appName),
            const Divider(),
            _buildInfoRow('Version', '1.0.0'),
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
