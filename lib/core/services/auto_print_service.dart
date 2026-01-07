import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../../core/models/cart.dart';
import 'thermal_print_service.dart';

/// Service for auto-printing receipts using saved default printer
class AutoPrintService {
  static const String _printerNameKey = 'default_printer_name';
  static const String _printerAddressKey = 'default_printer_address';
  static const String _printerConnectionTypeKey = 'default_printer_connection_type';
  static const String _autoPrintKey = 'auto_print_enabled';

  final ThermalPrintService _printService = ThermalPrintService();

  /// Check if auto-print is enabled
  Future<bool> isAutoPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoPrintKey) ?? true;
  }

  /// Check if a default printer is configured
  Future<bool> hasDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_printerAddressKey);
    return address != null && address.isNotEmpty;
  }

  /// Get saved printer info
  Future<Map<String, String?>> getSavedPrinterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_printerNameKey),
      'address': prefs.getString(_printerAddressKey),
      'connectionType': prefs.getString(_printerConnectionTypeKey),
    };
  }

  /// Auto-print a receipt for an order
  /// Returns true if printing was successful or if auto-print is disabled
  /// Returns false if printing failed
  Future<AutoPrintResult> autoPrint(Order order) async {
    debugPrint('🖨️ AUTO_PRINT: Starting auto-print process...');

    // Check if auto-print is enabled
    final autoPrintEnabled = await isAutoPrintEnabled();
    if (!autoPrintEnabled) {
      debugPrint('🖨️ AUTO_PRINT: Auto-print is disabled');
      return AutoPrintResult(
        success: true,
        message: 'Auto-print disabled',
        didPrint: false,
      );
    }

    // Check if we have a default printer
    final hasPrinter = await hasDefaultPrinter();
    if (!hasPrinter) {
      debugPrint('🖨️ AUTO_PRINT: No default printer configured');
      return AutoPrintResult(
        success: true,
        message: 'No printer configured',
        didPrint: false,
      );
    }

    // Get printer info
    final printerInfo = await getSavedPrinterInfo();
    debugPrint('🖨️ AUTO_PRINT: Using printer: ${printerInfo['name']} (${printerInfo['address']})');

    try {
      // Initialize print service
      await _printService.init();

      // Get connection type
      final connectionTypeStr = printerInfo['connectionType'] ?? 'USB';
      ConnectionType connectionType;
      switch (connectionTypeStr) {
        case 'BLE':
          connectionType = ConnectionType.BLE;
          break;
        case 'NETWORK':
          connectionType = ConnectionType.NETWORK;
          break;
        default:
          connectionType = ConnectionType.USB;
      }

      // Scan for printers
      debugPrint('🖨️ AUTO_PRINT: Scanning for printers...');
      await _printService.startScan(connectionTypes: [connectionType]);
      await Future.delayed(const Duration(seconds: 2));

      // Find the saved printer
      final printers = _printService.availablePrinters;
      debugPrint('🖨️ AUTO_PRINT: Found ${printers.length} printers');

      Printer? targetPrinter;
      for (final printer in printers) {
        if (printer.address == printerInfo['address']) {
          targetPrinter = printer;
          break;
        }
      }

      if (targetPrinter == null) {
        debugPrint('🖨️ AUTO_PRINT: Saved printer not found');
        return AutoPrintResult(
          success: false,
          message: 'Printer not found. Please check connection.',
          didPrint: false,
        );
      }

      // Select and connect to printer
      _printService.selectPrinter(targetPrinter);

      // Print the receipt
      debugPrint('🖨️ AUTO_PRINT: Printing receipt...');
      final printSuccess = await _printService.printReceipt(order, autoCut: true);

      if (printSuccess) {
        debugPrint('🖨️ AUTO_PRINT: Print successful!');
        return AutoPrintResult(
          success: true,
          message: 'Receipt printed successfully',
          didPrint: true,
        );
      } else {
        debugPrint('🖨️ AUTO_PRINT: Print failed');
        return AutoPrintResult(
          success: false,
          message: 'Print failed',
          didPrint: false,
        );
      }
    } catch (e) {
      debugPrint('🖨️ AUTO_PRINT: Error: $e');
      return AutoPrintResult(
        success: false,
        message: 'Print error: ${e.toString()}',
        didPrint: false,
      );
    }
  }
}

/// Result of auto-print operation
class AutoPrintResult {
  final bool success;
  final String message;
  final bool didPrint;

  AutoPrintResult({
    required this.success,
    required this.message,
    required this.didPrint,
  });
}
