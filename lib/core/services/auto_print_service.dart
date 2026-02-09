import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/cart.dart';
import 'print_service_interface.dart';
import 'print_service_factory.dart';
import 'file_logger.dart';

/// Service for auto-printing receipts using saved default printer.
/// Uses a static lock to serialize all print operations and prevent
/// concurrent scans from corrupting the shared ThermalPrintService singleton.
class AutoPrintService {
  static const String _printerNameKey = 'default_printer_name';
  static const String _printerAddressKey = 'default_printer_address';
  static const String _printerConnectionTypeKey = 'default_printer_connection_type';
  static const String _autoPrintKey = 'auto_print_enabled';

  /// Static lock shared across all AutoPrintService instances.
  /// Ensures only one print job runs at a time since ThermalPrintService
  /// is a singleton with shared mutable state.
  static Completer<void>? _printLock;

  PrintServiceInterface? _printServiceInstance;

  PrintServiceInterface get _printService {
    _printServiceInstance ??= PrintServiceFactory.getInstance();
    return _printServiceInstance!;
  }

  /// Check if auto-print is enabled
  Future<bool> isAutoPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure fresh data

    final rawValue = prefs.getBool(_autoPrintKey);
    final result = rawValue ?? true;
    debugPrint('🖨️ AUTO_PRINT: isAutoPrintEnabled check - raw: $rawValue, result: $result');
    return result;
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

  /// Wait for any in-progress print job to finish, then acquire the lock
  Future<void> _acquireLock() async {
    while (_printLock != null) {
      await _printLock!.future;
    }
    _printLock = Completer<void>();
  }

  /// Release the lock so the next queued print job can proceed
  void _releaseLock() {
    final lock = _printLock;
    _printLock = null;
    lock?.complete();
  }

  /// Auto-print a receipt for an order
  /// Returns true if printing was successful or if auto-print is disabled
  /// Returns false if printing failed
  final _log = FileLogger.instance;

  Future<AutoPrintResult> autoPrint(Order order) async {
    debugPrint('🖨️ AUTO_PRINT: Starting auto-print process...');
    _log.info('PRINT: Starting auto-print for order ${order.code}');

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

    // Acquire lock - wait for any other print job to finish
    debugPrint('🖨️ AUTO_PRINT: Waiting for print lock...');
    await _acquireLock();
    debugPrint('🖨️ AUTO_PRINT: Lock acquired');

    try {
      // Initialize print service
      await _printService.init();

      // Try to find and print with retry
      final result = await _scanAndPrint(printerInfo, order);
      return result;
    } catch (e, stack) {
      debugPrint('🖨️ AUTO_PRINT: Error: $e');
      _log.error('PRINT: Error printing order ${order.code}', e, stack);
      return AutoPrintResult(
        success: false,
        message: 'Print error: ${e.toString()}',
        didPrint: false,
      );
    } finally {
      // Always stop scan and release lock
      try {
        _printService.stopScan();
      } catch (_) {}
      _releaseLock();
      debugPrint('🖨️ AUTO_PRINT: Lock released');
    }
  }

  /// Scan for printers and print, with one retry on failure
  Future<AutoPrintResult> _scanAndPrint(
    Map<String, String?> printerInfo,
    Order order,
  ) async {
    // First attempt with 2 second scan
    var printer = await _findPrinter(printerInfo, const Duration(seconds: 2));

    // Retry with longer scan if first attempt failed
    if (printer == null) {
      debugPrint('🖨️ AUTO_PRINT: First scan failed, retrying with longer timeout...');
      printer = await _findPrinter(printerInfo, const Duration(seconds: 4));
    }

    if (printer == null) {
      debugPrint('🖨️ AUTO_PRINT: No printers found after retry');
      _log.warn('PRINT: No printers found for order ${order.code} after 2 scan attempts');
      return AutoPrintResult(
        success: false,
        message: 'Printer not found. Please check connection.',
        didPrint: false,
      );
    }

    // Select and print
    _printService.selectPrinter(printer);

    debugPrint('🖨️ AUTO_PRINT: Printing receipt on ${printer.name}...');
    _log.info('PRINT: Printing order ${order.code} on ${printer.name} (${printer.address})');
    final printSuccess = await _printService.printReceipt(order, autoCut: true);

    if (printSuccess) {
      debugPrint('🖨️ AUTO_PRINT: Print successful!');
      _log.info('PRINT: Success - order ${order.code}');
      return AutoPrintResult(
        success: true,
        message: 'Receipt printed successfully',
        didPrint: true,
      );
    } else {
      debugPrint('🖨️ AUTO_PRINT: Print failed');
      _log.warn('PRINT: Failed - order ${order.code} on ${printer.name}');
      return AutoPrintResult(
        success: false,
        message: 'Print failed',
        didPrint: false,
      );
    }
  }

  /// Scan for printers and try to find the saved one (or fallback to first available)
  Future<PrinterInfo?> _findPrinter(
    Map<String, String?> printerInfo,
    Duration scanDuration,
  ) async {
    debugPrint('🖨️ AUTO_PRINT: Scanning for ${scanDuration.inSeconds}s...');

    await _printService.startScan(connectionTypes: [
      PrinterConnectionType.usb,
      PrinterConnectionType.bluetooth,
      PrinterConnectionType.network,
    ]);
    await Future.delayed(scanDuration);

    final printers = _printService.availablePrinters;
    debugPrint('🖨️ AUTO_PRINT: Found ${printers.length} printers');

    if (printers.isEmpty) return null;

    // Try exact address match first
    for (final printer in printers) {
      if (printer.address == printerInfo['address']) {
        debugPrint('🖨️ AUTO_PRINT: Found saved printer: ${printer.name}');
        return printer;
      }
    }

    // Fallback to first available printer
    final fallback = printers.first;
    debugPrint('🖨️ AUTO_PRINT: Saved printer not found, using fallback: ${fallback.name}');
    return fallback;
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
