import '../models/cart.dart';

/// Abstract interface for print services
/// Implemented differently for desktop (native USB) and web (Web Serial API)
abstract class PrintServiceInterface {
  /// Get list of available printers
  List<PrinterInfo> get availablePrinters;

  /// Get currently selected printer
  PrinterInfo? get selectedPrinter;

  /// Initialize the print service
  Future<void> init();

  /// Start scanning for available printers
  Future<void> startScan({List<PrinterConnectionType> connectionTypes});

  /// Stop scanning for printers
  void stopScan();

  /// Select a printer for printing
  void selectPrinter(PrinterInfo printer);

  /// Connect to the selected printer
  Future<bool> connect();

  /// Disconnect from the printer
  Future<void> disconnect();

  /// Print a receipt for an order
  Future<bool> printReceipt(Order order, {bool autoCut = true});

  /// Print raw ESC/POS data
  Future<bool> printRaw(List<int> data);

  /// Check if Web Serial API is supported (web only)
  bool get isWebSerialSupported;

  /// Dispose resources
  void dispose();
}

/// Platform-agnostic printer info
class PrinterInfo {
  final String name;
  final String address;
  final PrinterConnectionType connectionType;
  final dynamic nativePrinter; // Native printer object (platform-specific)

  PrinterInfo({
    required this.name,
    required this.address,
    required this.connectionType,
    this.nativePrinter,
  });

  @override
  String toString() => 'PrinterInfo(name: $name, address: $address, type: $connectionType)';
}

/// Connection types for printers
enum PrinterConnectionType {
  usb,
  serial,
  bluetooth,
  network,
}

/// Convert connection type to string
extension PrinterConnectionTypeExtension on PrinterConnectionType {
  String get name {
    switch (this) {
      case PrinterConnectionType.usb:
        return 'USB';
      case PrinterConnectionType.serial:
        return 'Serial';
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
      case PrinterConnectionType.network:
        return 'Network';
    }
  }

  static PrinterConnectionType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'USB':
        return PrinterConnectionType.usb;
      case 'SERIAL':
        return PrinterConnectionType.serial;
      case 'BLE':
      case 'BLUETOOTH':
        return PrinterConnectionType.bluetooth;
      case 'NETWORK':
        return PrinterConnectionType.network;
      default:
        return PrinterConnectionType.usb;
    }
  }
}
