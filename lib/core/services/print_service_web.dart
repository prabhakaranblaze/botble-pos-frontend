import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:intl/intl.dart';
import '../models/cart.dart';
import '../../shared/constants/app_constants.dart';
import 'print_service_interface.dart';

/// Factory function for web platform
PrintServiceInterface createPrintService() => WebPrintService();

/// Web implementation of PrintService using Web Serial API
/// Only works in Chrome/Edge browsers
class WebPrintService implements PrintServiceInterface {
  static final WebPrintService _instance = WebPrintService._internal();
  factory WebPrintService() => _instance;
  WebPrintService._internal();

  PrinterInfo? _selectedPrinter;
  final List<PrinterInfo> _availablePrinters = [];
  dynamic _serialPort;
  bool _isConnected = false;

  @override
  List<PrinterInfo> get availablePrinters => _availablePrinters;

  @override
  PrinterInfo? get selectedPrinter => _selectedPrinter;

  @override
  bool get isWebSerialSupported {
    try {
      return js.context.hasProperty('navigator') &&
          js.context['navigator'].hasProperty('serial');
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> init() async {
    debugPrint('🖨️ WebPrintService: Initializing...');
    if (!isWebSerialSupported) {
      debugPrint('🖨️ WebPrintService: Web Serial API not supported');
    }
  }

  @override
  Future<void> startScan({
    List<PrinterConnectionType> connectionTypes = const [
      PrinterConnectionType.usb,
      PrinterConnectionType.serial,
    ],
  }) async {
    if (!isWebSerialSupported) {
      debugPrint('🖨️ WebPrintService: Web Serial API not supported');
      return;
    }

    debugPrint('🖨️ WebPrintService: Requesting serial port...');

    try {
      // Request port from user (browser will show picker)
      final port = await _requestSerialPort();

      if (port != null) {
        final printerInfo = PrinterInfo(
          name: 'Serial Printer',
          address: 'web-serial',
          connectionType: PrinterConnectionType.serial,
          nativePrinter: port,
        );

        _availablePrinters.clear();
        _availablePrinters.add(printerInfo);
        _selectedPrinter = printerInfo;
        _serialPort = port;

        debugPrint('🖨️ WebPrintService: Port selected');
      }
    } catch (e) {
      debugPrint('🖨️ WebPrintService: Error requesting port: $e');
    }
  }

  Future<dynamic> _requestSerialPort() async {
    try {
      final serial = js.context['navigator']['serial'];
      final port = await js.context.callMethod('eval', [
        '''
        (async () => {
          try {
            const port = await navigator.serial.requestPort();
            return port;
          } catch (e) {
            console.error('Serial port request failed:', e);
            return null;
          }
        })()
        '''
      ]);
      return port;
    } catch (e) {
      debugPrint('🖨️ WebPrintService: requestPort error: $e');
      return null;
    }
  }

  @override
  void stopScan() {
    // No continuous scanning on web
  }

  @override
  void selectPrinter(PrinterInfo printer) {
    _selectedPrinter = printer;
    _serialPort = printer.nativePrinter;
    debugPrint('🖨️ WebPrintService: Selected printer: ${printer.name}');
  }

  @override
  Future<bool> connect() async {
    if (_serialPort == null) {
      debugPrint('🖨️ WebPrintService: No port selected');
      return false;
    }

    try {
      // Open the port with typical thermal printer settings
      await js.context.callMethod('eval', [
        '''
        (async (port) => {
          await port.open({ baudRate: 9600 });
        })(${_serialPort})
        '''
      ]);

      _isConnected = true;
      debugPrint('🖨️ WebPrintService: Connected');
      return true;
    } catch (e) {
      debugPrint('🖨️ WebPrintService: Connection error: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_serialPort == null || !_isConnected) return;

    try {
      await js.context.callMethod('eval', [
        '''
        (async (port) => {
          await port.close();
        })(${_serialPort})
        '''
      ]);
      _isConnected = false;
      debugPrint('🖨️ WebPrintService: Disconnected');
    } catch (e) {
      debugPrint('🖨️ WebPrintService: Disconnect error: $e');
    }
  }

  @override
  Future<bool> printReceipt(Order order, {bool autoCut = true}) async {
    if (_serialPort == null) {
      debugPrint('🖨️ WebPrintService: No printer selected');
      return false;
    }

    try {
      final receiptData = _buildReceiptCommands(order, autoCut: autoCut);
      return await printRaw(receiptData);
    } catch (e) {
      debugPrint('🖨️ WebPrintService: Print error: $e');
      return false;
    }
  }

  @override
  Future<bool> printRaw(List<int> data) async {
    if (_serialPort == null) {
      debugPrint('🖨️ WebPrintService: No port selected');
      return false;
    }

    try {
      // Connect if not connected
      if (!_isConnected) {
        final connected = await connect();
        if (!connected) return false;
      }

      // Convert to Uint8Array and send
      final uint8Data = Uint8List.fromList(data);

      // Use Web Serial API to write data
      await js.context.callMethod('eval', [
        '''
        (async (port, data) => {
          const writer = port.writable.getWriter();
          await writer.write(new Uint8Array(data));
          writer.releaseLock();
        })(${_serialPort}, [${uint8Data.join(',')}])
        '''
      ]);

      debugPrint('🖨️ WebPrintService: Data sent (${data.length} bytes)');
      return true;
    } catch (e) {
      debugPrint('🖨️ WebPrintService: Write error: $e');
      return false;
    }
  }

  /// Build ESC/POS receipt commands (same as desktop)
  List<int> _buildReceiptCommands(Order order, {bool autoCut = true}) {
    final List<int> commands = [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Initialize printer
    commands.addAll([0x1B, 0x40]); // ESC @

    // Store name - centered, bold, double height
    commands.addAll([0x1B, 0x61, 0x01]); // Center align
    commands.addAll([0x1B, 0x45, 0x01]); // Bold on
    commands.addAll([0x1D, 0x21, 0x10]); // Double height
    commands.addAll(_textToBytes(AppConstants.appName));
    commands.add(0x0A); // New line
    commands.addAll([0x1D, 0x21, 0x00]); // Normal size
    commands.addAll([0x1B, 0x45, 0x00]); // Bold off

    // Store info
    commands.addAll(_textToBytes('POS Receipt'));
    commands.add(0x0A);
    commands.add(0x0A);

    // Order info - left aligned
    commands.addAll([0x1B, 0x61, 0x00]); // Left align
    commands.addAll(_textToBytes('Order: ${order.code}'));
    commands.add(0x0A);
    commands.addAll(_textToBytes('Date: ${dateFormat.format(order.createdAt)}'));
    commands.add(0x0A);

    // Customer (if available)
    if (order.customer != null) {
      commands.addAll(_textToBytes('Customer: ${order.customer!.name}'));
      commands.add(0x0A);
    }

    // Payment method
    String paymentInfo = 'Payment: ${_formatPaymentMethod(order.paymentMethod)}';
    if (order.cardLastFour != null) {
      paymentInfo += ' (*${order.cardLastFour})';
    }
    commands.addAll(_textToBytes(paymentInfo));
    commands.add(0x0A);

    // Divider
    commands.add(0x0A);
    commands.addAll(_textToBytes('--------------------------------'));
    commands.add(0x0A);

    // Column headers
    commands.addAll([0x1B, 0x45, 0x01]); // Bold on
    commands.addAll(_textToBytes(_formatLine('Item', 'Qty', 'Amount')));
    commands.add(0x0A);
    commands.addAll([0x1B, 0x45, 0x00]); // Bold off
    commands.addAll(_textToBytes('--------------------------------'));
    commands.add(0x0A);

    // Items
    for (final item in order.items) {
      final itemName = _truncateText(item.name, 20);
      final qty = item.quantity.toString();
      final amount = AppCurrency.format(item.total);

      commands.addAll(_textToBytes(_formatLine(itemName, qty, amount)));
      commands.add(0x0A);
    }

    // Divider
    commands.addAll(_textToBytes('--------------------------------'));
    commands.add(0x0A);

    // Subtotal
    commands.addAll(_textToBytes(_formatTotalLine('Subtotal:', AppCurrency.format(order.subTotal))));
    commands.add(0x0A);

    // Tax
    if (order.taxAmount > 0) {
      commands.addAll(_textToBytes(_formatTotalLine('Tax:', AppCurrency.format(order.taxAmount))));
      commands.add(0x0A);
    }

    // Discount
    if (order.discountAmount > 0) {
      commands.addAll(_textToBytes(_formatTotalLine('Discount:', '-${AppCurrency.format(order.discountAmount)}')));
      commands.add(0x0A);
    }

    // Total - bold and larger
    commands.addAll(_textToBytes('--------------------------------'));
    commands.add(0x0A);
    commands.addAll([0x1B, 0x45, 0x01]); // Bold on
    commands.addAll([0x1D, 0x21, 0x10]); // Double height
    commands.addAll(_textToBytes(_formatTotalLine('TOTAL:', AppCurrency.format(order.amount))));
    commands.add(0x0A);
    commands.addAll([0x1D, 0x21, 0x00]); // Normal size
    commands.addAll([0x1B, 0x45, 0x00]); // Bold off

    // Cash payment details
    if (order.cashReceived != null && order.changeGiven != null) {
      commands.add(0x0A);
      commands.addAll(_textToBytes(_formatTotalLine('Cash:', AppCurrency.format(order.cashReceived!))));
      commands.add(0x0A);
      commands.addAll(_textToBytes(_formatTotalLine('Change:', AppCurrency.format(order.changeGiven!))));
      commands.add(0x0A);
    }

    // Footer
    commands.add(0x0A);
    commands.addAll([0x1B, 0x61, 0x01]); // Center align
    commands.addAll(_textToBytes('--------------------------------'));
    commands.add(0x0A);
    commands.addAll(_textToBytes('Thank you for your purchase!'));
    commands.add(0x0A);
    commands.addAll(_textToBytes('Please come again'));
    commands.add(0x0A);
    commands.add(0x0A);

    // Feed and cut
    commands.addAll([0x1B, 0x64, 0x04]); // Feed 4 lines
    if (autoCut) {
      commands.addAll([0x1D, 0x56, 0x00]); // Full cut
    }

    return commands;
  }

  List<int> _textToBytes(String text) => text.codeUnits;

  String _formatLine(String col1, String col2, String col3) {
    const totalWidth = 32;
    const col2Width = 4;
    const col3Width = 10;
    const col1Width = totalWidth - col2Width - col3Width;

    final c1 = col1.padRight(col1Width).substring(0, col1Width);
    final c2 = col2.padLeft(col2Width);
    final c3 = col3.padLeft(col3Width);

    return '$c1$c2$c3';
  }

  String _formatTotalLine(String label, String value) {
    const totalWidth = 32;
    const valueWidth = 12;
    const labelWidth = totalWidth - valueWidth;

    final l = label.padRight(labelWidth);
    final v = value.padLeft(valueWidth);

    return '$l$v';
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'pos_cash':
      case 'cash':
        return 'Cash';
      case 'pos_card':
      case 'card':
        return 'Card';
      default:
        return method.toUpperCase();
    }
  }

  @override
  void dispose() {
    disconnect();
  }
}
