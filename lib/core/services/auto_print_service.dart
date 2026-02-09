import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/cart.dart';
import 'print_service_interface.dart';
import 'print_service_factory.dart';
import 'file_logger.dart';

/// Service for auto-printing receipts using saved default printer.
/// Uses a static lock to serialize all print operations and prevent
/// concurrent access to the shared ThermalPrintService singleton.
///
/// Print strategy: direct connect first (instant), scan only as fallback.
class AutoPrintService {
  static const String _printerNameKey = 'default_printer_name';
  static const String _printerAddressKey = 'default_printer_address';
  static const String _printerConnectionTypeKey =
      'default_printer_connection_type';
  static const String _autoPrintKey = 'auto_print_enabled';

  /// Static lock shared across all AutoPrintService instances.
  static Completer<void>? _printLock;

  final _log = FileLogger.instance;

  PrintServiceInterface? _printServiceInstance;

  PrintServiceInterface get _printService {
    _printServiceInstance ??= PrintServiceFactory.getInstance();
    return _printServiceInstance!;
  }

  /// Check if auto-print is enabled
  Future<bool> isAutoPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final rawValue = prefs.getBool(_autoPrintKey);
    final result = rawValue ?? true;
    debugPrint(
        '🖨️ AUTO_PRINT: isAutoPrintEnabled check - raw: $rawValue, result: $result');
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

  Future<void> _acquireLock() async {
    while (_printLock != null) {
      await _printLock!.future;
    }
    _printLock = Completer<void>();
  }

  void _releaseLock() {
    final lock = _printLock;
    _printLock = null;
    lock?.complete();
  }

  /// Auto-print a receipt for an order.
  /// Strategy: direct connect first (instant), scan only as fallback.
  Future<AutoPrintResult> autoPrint(Order order) async {
    debugPrint('🖨️ AUTO_PRINT: Starting auto-print for order ${order.code}');
    _log.info('PRINT: Starting auto-print for order ${order.code}');

    // Check if auto-print is enabled
    final autoPrintEnabled = await isAutoPrintEnabled();
    if (!autoPrintEnabled) {
      debugPrint('🖨️ AUTO_PRINT: Auto-print is disabled');
      return AutoPrintResult(
          success: true, message: 'Auto-print disabled', didPrint: false);
    }

    // Check if we have a default printer
    final hasPrinter = await hasDefaultPrinter();
    if (!hasPrinter) {
      debugPrint('🖨️ AUTO_PRINT: No default printer configured');
      return AutoPrintResult(
          success: true, message: 'No printer configured', didPrint: false);
    }

    // Get printer info
    final printerInfo = await getSavedPrinterInfo();
    final printerName = printerInfo['name'] ?? 'Unknown';
    final printerAddress = printerInfo['address'] ?? '';
    final connectionTypeStr = printerInfo['connectionType'] ?? 'USB';
    debugPrint(
        '🖨️ AUTO_PRINT: Printer: $printerName ($printerAddress) [$connectionTypeStr]');

    // Acquire lock
    await _acquireLock();

    try {
      await _printService.init();

      // Strategy 1: Direct connect (instant - no scan needed)
      debugPrint('🖨️ AUTO_PRINT: Trying direct connect...');
      _log.info('PRINT: Direct connect to $printerName ($printerAddress)');

      final connectionType =
          PrinterConnectionTypeExtension.fromString(connectionTypeStr);
      _printService.selectPrinterFromSaved(
        name: printerName,
        address: printerAddress,
        connectionType: connectionType,
      );

      final directSuccess =
          await _printService.printReceipt(order, autoCut: true);
      if (directSuccess) {
        debugPrint('🖨️ AUTO_PRINT: Direct print successful!');
        _log.info('PRINT: Success (direct) - order ${order.code}');
        return AutoPrintResult(
            success: true,
            message: 'Receipt printed successfully',
            didPrint: true);
      }

      // Strategy 2: Scan and find printer (fallback)
      debugPrint(
          '🖨️ AUTO_PRINT: Direct connect failed, falling back to scan...');
      _log.info('PRINT: Direct failed, scanning...');

      final scanPrinter = await _findPrinterByScan(printerInfo);
      if (scanPrinter == null) {
        _log.warn(
            'PRINT: No printers found for order ${order.code} after scan');
        return AutoPrintResult(
            success: false,
            message: 'Printer not found. Please check connection.',
            didPrint: false);
      }

      _printService.selectPrinter(scanPrinter);
      final scanSuccess =
          await _printService.printReceipt(order, autoCut: true);

      if (scanSuccess) {
        debugPrint('🖨️ AUTO_PRINT: Scan+print successful!');
        _log.info(
            'PRINT: Success (scan) - order ${order.code} on ${scanPrinter.name}');
        return AutoPrintResult(
            success: true,
            message: 'Receipt printed successfully',
            didPrint: true);
      }

      debugPrint('🖨️ AUTO_PRINT: Print failed');
      _log.warn('PRINT: Failed - order ${order.code}');
      return AutoPrintResult(
          success: false, message: 'Print failed', didPrint: false);
    } catch (e, stack) {
      debugPrint('🖨️ AUTO_PRINT: Error: $e');
      _log.error('PRINT: Error printing order ${order.code}', e, stack);
      return AutoPrintResult(
          success: false,
          message: 'Print error: ${e.toString()}',
          didPrint: false);
    } finally {
      try {
        _printService.stopScan();
      } catch (_) {}
      _releaseLock();
    }
  }

  /// Fallback: scan for printers and find the saved one (or first available)
  Future<PrinterInfo?> _findPrinterByScan(
      Map<String, String?> printerInfo) async {
    debugPrint('🖨️ AUTO_PRINT: Scanning for 3s...');

    await _printService.startScan(connectionTypes: [
      PrinterConnectionType.usb,
      PrinterConnectionType.bluetooth,
      PrinterConnectionType.network,
    ]);
    await Future.delayed(const Duration(seconds: 3));

    final printers = _printService.availablePrinters;
    debugPrint('🖨️ AUTO_PRINT: Scan found ${printers.length} printers');

    if (printers.isEmpty) return null;

    // Try exact address match
    for (final printer in printers) {
      if (printer.address == printerInfo['address']) {
        return printer;
      }
    }

    // Fallback to first available
    return printers.first;
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
