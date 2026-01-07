import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../models/cart.dart';
import '../../shared/constants/app_constants.dart';
import 'package:intl/intl.dart';

/// Service for thermal receipt printing with ESC/POS commands
class ThermalPrintService {
  static final ThermalPrintService _instance = ThermalPrintService._internal();
  factory ThermalPrintService() => _instance;
  ThermalPrintService._internal();

  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  Printer? _selectedPrinter;
  List<Printer> _availablePrinters = [];
  StreamSubscription<List<Printer>>? _printerSubscription;

  Printer? get selectedPrinter => _selectedPrinter;
  List<Printer> get availablePrinters => _availablePrinters;

  /// Initialize (does not auto-scan)
  Future<void> init() async {
    // No auto-scan - call startScan() explicitly when needed
  }

  /// Start scanning for available printers
  Future<void> startScan({
    List<ConnectionType> connectionTypes = const [
      ConnectionType.USB,
      ConnectionType.BLE,
      ConnectionType.NETWORK,
    ],
  }) async {
    // Cancel any existing subscription first
    _printerSubscription?.cancel();
    _printerSubscription = null;
    _availablePrinters = [];

    try {
      debugPrint('🔍 Starting printer scan...');

      // Listen to devices stream (only log once when list changes significantly)
      int lastCount = -1;
      _printerSubscription = _flutterThermalPrinterPlugin.devicesStream.listen((printers) {
        _availablePrinters = printers;
        // Only log when count changes to reduce spam
        if (printers.length != lastCount) {
          lastCount = printers.length;
          debugPrint('🔍 Found ${printers.length} printers');
        }
      });

      // Start scanning using getPrinters
      await _flutterThermalPrinterPlugin.getPrinters(
        connectionTypes: connectionTypes,
      );
    } catch (e) {
      debugPrint('🔍 Error scanning for printers: $e');
    }
  }

  /// Stop scanning for printers
  void stopScan() {
    try {
      _flutterThermalPrinterPlugin.stopScan();
      _printerSubscription?.cancel();
      _printerSubscription = null;
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Select a printer for printing
  void selectPrinter(Printer printer) {
    _selectedPrinter = printer;
    debugPrint('Selected printer: ${printer.name}');
  }

  /// Connect to the selected printer
  Future<bool> connect() async {
    if (_selectedPrinter == null) {
      debugPrint('No printer selected');
      return false;
    }

    try {
      final connected = await _flutterThermalPrinterPlugin.connect(_selectedPrinter!);
      debugPrint('Printer connected: $connected');
      return connected;
    } catch (e) {
      debugPrint('Failed to connect to printer: $e');
      return false;
    }
  }

  /// Disconnect from the printer
  Future<void> disconnect() async {
    if (_selectedPrinter != null) {
      try {
        await _flutterThermalPrinterPlugin.disconnect(_selectedPrinter!);
      } catch (e) {
        debugPrint('Error disconnecting: $e');
      }
    }
  }

  /// Print a receipt for an order
  Future<bool> printReceipt(Order order, {bool autoCut = true}) async {
    if (_selectedPrinter == null) {
      debugPrint('No printer selected');
      return false;
    }

    try {
      final connected = await connect();
      if (!connected) return false;

      final receiptData = _buildReceiptCommands(order, autoCut: autoCut);

      await _flutterThermalPrinterPlugin.printData(
        _selectedPrinter!,
        receiptData,
        longData: true,
      );

      debugPrint('Print completed');
      return true;
    } catch (e) {
      debugPrint('Print failed: $e');
      return false;
    }
  }

  /// Build ESC/POS receipt commands
  List<int> _buildReceiptCommands(Order order, {bool autoCut = true}) {
    final List<int> commands = [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Initialize printer
    commands.addAll(_escInit());

    // Store name - centered, bold, double height
    commands.addAll(_escAlign(Align.center));
    commands.addAll(_escBoldOn());
    commands.addAll(_escDoubleHeight());
    commands.addAll(_textToBytes(AppConstants.appName));
    commands.addAll(_escNewLine());
    commands.addAll(_escNormalSize());
    commands.addAll(_escBoldOff());

    // Store info
    commands.addAll(_textToBytes('POS Receipt'));
    commands.addAll(_escNewLine());
    commands.addAll(_escNewLine());

    // Order info - left aligned
    commands.addAll(_escAlign(Align.left));
    commands.addAll(_textToBytes('Order: ${order.code}'));
    commands.addAll(_escNewLine());
    commands.addAll(_textToBytes('Date: ${dateFormat.format(order.createdAt)}'));
    commands.addAll(_escNewLine());
    commands.addAll(_textToBytes('Payment: ${_formatPaymentMethod(order.paymentMethod)}'));
    commands.addAll(_escNewLine());

    // Divider
    commands.addAll(_escNewLine());
    commands.addAll(_textToBytes('--------------------------------'));
    commands.addAll(_escNewLine());

    // Column headers
    commands.addAll(_escBoldOn());
    commands.addAll(_textToBytes(_formatLine('Item', 'Qty', 'Amount')));
    commands.addAll(_escNewLine());
    commands.addAll(_escBoldOff());
    commands.addAll(_textToBytes('--------------------------------'));
    commands.addAll(_escNewLine());

    // Items
    for (final item in order.items) {
      // Item name (may wrap to multiple lines for long names)
      final itemName = _truncateText(item.name, 20);
      final qty = item.quantity.toString();
      final amount = AppCurrency.format(item.total);

      commands.addAll(_textToBytes(_formatLine(itemName, qty, amount)));
      commands.addAll(_escNewLine());
    }

    // Divider
    commands.addAll(_textToBytes('--------------------------------'));
    commands.addAll(_escNewLine());

    // Subtotal
    commands.addAll(_textToBytes(_formatTotalLine('Subtotal:', AppCurrency.format(order.subTotal))));
    commands.addAll(_escNewLine());

    // Tax
    if (order.taxAmount > 0) {
      commands.addAll(_textToBytes(_formatTotalLine('Tax:', AppCurrency.format(order.taxAmount))));
      commands.addAll(_escNewLine());
    }

    // Discount
    if (order.discountAmount > 0) {
      commands.addAll(_textToBytes(_formatTotalLine('Discount:', '-${AppCurrency.format(order.discountAmount)}')));
      commands.addAll(_escNewLine());
    }

    // Total - bold and larger
    commands.addAll(_textToBytes('--------------------------------'));
    commands.addAll(_escNewLine());
    commands.addAll(_escBoldOn());
    commands.addAll(_escDoubleHeight());
    commands.addAll(_textToBytes(_formatTotalLine('TOTAL:', AppCurrency.format(order.amount))));
    commands.addAll(_escNewLine());
    commands.addAll(_escNormalSize());
    commands.addAll(_escBoldOff());

    // Footer
    commands.addAll(_escNewLine());
    commands.addAll(_escAlign(Align.center));
    commands.addAll(_textToBytes('--------------------------------'));
    commands.addAll(_escNewLine());
    commands.addAll(_textToBytes('Thank you for your purchase!'));
    commands.addAll(_escNewLine());
    commands.addAll(_textToBytes('Please come again'));
    commands.addAll(_escNewLine());
    commands.addAll(_escNewLine());

    // Feed and cut
    commands.addAll(_escFeed(4));
    if (autoCut) {
      commands.addAll(_escCut());
    }

    return commands;
  }

  // ============ ESC/POS Commands ============

  /// Initialize printer
  List<int> _escInit() => [0x1B, 0x40]; // ESC @

  /// Set text alignment
  List<int> _escAlign(Align align) {
    int a = 0;
    switch (align) {
      case Align.left:
        a = 0;
        break;
      case Align.center:
        a = 1;
        break;
      case Align.right:
        a = 2;
        break;
    }
    return [0x1B, 0x61, a]; // ESC a n
  }

  /// Bold on
  List<int> _escBoldOn() => [0x1B, 0x45, 0x01]; // ESC E 1

  /// Bold off
  List<int> _escBoldOff() => [0x1B, 0x45, 0x00]; // ESC E 0

  /// Double height text
  List<int> _escDoubleHeight() => [0x1D, 0x21, 0x10]; // GS ! 16

  /// Normal size text
  List<int> _escNormalSize() => [0x1D, 0x21, 0x00]; // GS ! 0

  /// New line
  List<int> _escNewLine() => [0x0A]; // LF

  /// Feed paper n lines
  List<int> _escFeed(int lines) => [0x1B, 0x64, lines]; // ESC d n

  /// Cut paper (full cut)
  List<int> _escCut() => [0x1D, 0x56, 0x00]; // GS V 0 (full cut)

  /// Partial cut (leaves small connection)
  List<int> _escPartialCut() => [0x1D, 0x56, 0x01]; // GS V 1 (partial cut)

  /// Convert text to bytes
  List<int> _textToBytes(String text) {
    return text.codeUnits;
  }

  // ============ Formatting Helpers ============

  /// Format a 3-column line for items (32 char width for 58mm paper)
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

  /// Format a 2-column total line
  String _formatTotalLine(String label, String value) {
    const totalWidth = 32;
    const valueWidth = 12;
    const labelWidth = totalWidth - valueWidth;

    final l = label.padRight(labelWidth);
    final v = value.padLeft(valueWidth);

    return '$l$v';
  }

  /// Truncate text to max length
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }

  /// Format payment method for display
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

  /// Dispose resources
  void dispose() {
    stopScan();
    disconnect();
  }
}

enum Align { left, center, right }
