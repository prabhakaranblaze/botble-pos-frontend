import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/services/print_service_interface.dart';
import '../../core/services/print_service_factory.dart';

/// Web implementation of printer settings using Web Serial API
Widget buildPrinterSettingsCard(BuildContext context) {
  return const _WebPrinterSettingsCard();
}

class _WebPrinterSettingsCard extends StatefulWidget {
  const _WebPrinterSettingsCard();

  @override
  State<_WebPrinterSettingsCard> createState() => _WebPrinterSettingsCardState();
}

class _WebPrinterSettingsCardState extends State<_WebPrinterSettingsCard> {
  static const String _printerNameKey = 'default_printer_name';
  static const String _autoPrintKey = 'auto_print_enabled';

  String? _savedPrinterName;
  bool _autoPrintEnabled = true;
  bool _isConnecting = false;
  bool _isTesting = false;
  bool _isWebSerialSupported = false;

  @override
  void initState() {
    super.initState();
    _checkWebSerialSupport();
    _loadSavedPrinter();
  }

  void _checkWebSerialSupport() {
    try {
      _isWebSerialSupported = js.context.hasProperty('navigator') &&
          js.context['navigator'].hasProperty('serial');
    } catch (e) {
      _isWebSerialSupported = false;
    }
    setState(() {});
  }

  Future<void> _loadSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPrinterName = prefs.getString(_printerNameKey);
      _autoPrintEnabled = prefs.getBool(_autoPrintKey) ?? true;
    });
  }

  Future<void> _toggleAutoPrint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPrintKey, value);
    setState(() {
      _autoPrintEnabled = value;
    });
  }

  Future<void> _selectPrinter() async {
    if (!_isWebSerialSupported) {
      _showBrowserNotSupportedDialog();
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final printService = PrintServiceFactory.getInstance();
      await printService.startScan();

      if (printService.selectedPrinter != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_printerNameKey, 'Web Serial Printer');

        setState(() {
          _savedPrinterName = 'Web Serial Printer';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Printer connected successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isConnecting = false);
  }

  Future<void> _clearPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printerNameKey);

    final printService = PrintServiceFactory.getInstance();
    await printService.disconnect();

    setState(() {
      _savedPrinterName = null;
    });

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.defaultPrinterCleared ?? 'Default printer cleared')),
      );
    }
  }

  Future<void> _testPrint() async {
    if (_savedPrinterName == null) {
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
      final printService = PrintServiceFactory.getInstance();
      final testData = _buildTestReceipt();
      final success = await printService.printRaw(testData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Test print sent!' : 'Print failed'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isTesting = false);
  }

  List<int> _buildTestReceipt() {
    final List<int> commands = [];

    // Initialize + Center align
    commands.addAll([0x1B, 0x40, 0x1B, 0x61, 0x01]);

    // Bold + double height
    commands.addAll([0x1B, 0x45, 0x01, 0x1D, 0x21, 0x10]);
    commands.addAll('TEST PRINT'.codeUnits);
    commands.add(0x0A);

    // Normal
    commands.addAll([0x1D, 0x21, 0x00, 0x1B, 0x45, 0x00]);
    commands.addAll('--------------------------------'.codeUnits);
    commands.add(0x0A);
    commands.addAll(AppConstants.appName.codeUnits);
    commands.add(0x0A);
    commands.addAll('Web Serial Printer'.codeUnits);
    commands.add(0x0A);
    commands.addAll('--------------------------------'.codeUnits);
    commands.add(0x0A);
    commands.addAll('Printer is working!'.codeUnits);
    commands.addAll([0x0A, 0x0A]);

    // Feed and cut
    commands.addAll([0x1B, 0x64, 0x04, 0x1D, 0x56, 0x00]);

    return commands;
  }

  void _showBrowserNotSupportedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Browser Not Supported'),
        content: const Text(
          'Web Serial API is not supported in this browser.\n\n'
          'Please use Google Chrome or Microsoft Edge for printer support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web Serial Support Status
            if (!_isWebSerialSupported)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use Chrome or Edge for printer support',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),

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
                      Text(
                        l10n?.defaultPrinter ?? 'Default Printer',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _savedPrinterName ?? (l10n?.notConfigured ?? 'Not configured'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _savedPrinterName != null ? null : AppColors.textSecondary,
                        ),
                      ),
                      const Text(
                        'Web Serial (Chrome/Edge)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    tooltip: l10n?.testPrint ?? 'Test Print',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearPrinter,
                    tooltip: l10n?.clear ?? 'Clear',
                  ),
                ],
              ],
            ),

            const Divider(height: 24),

            // Auto Print Toggle
            SwitchListTile(
              title: Text(l10n?.autoPrintOnPayment ?? 'Auto Print on Payment'),
              subtitle: Text(l10n?.autoPrintDescription ?? 'Automatically print receipt when order is paid'),
              value: _autoPrintEnabled,
              onChanged: _toggleAutoPrint,
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(height: 24),

            // Connect Printer Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isConnecting || !_isWebSerialSupported ? null : _selectPrinter,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.usb),
                label: Text(_isConnecting
                    ? 'Connecting...'
                    : _savedPrinterName != null
                        ? 'Change Printer'
                        : 'Connect Printer'),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Web Printer Setup',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Connect your thermal printer via USB\n'
                    '2. Click "Connect Printer" button\n'
                    '3. Select your printer from the browser popup\n'
                    '4. Grant permission to access the device',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
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
}
