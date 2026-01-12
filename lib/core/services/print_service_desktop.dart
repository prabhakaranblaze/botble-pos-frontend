import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'print_service_interface.dart';
import 'thermal_print_service.dart';
import '../models/cart.dart';

/// Factory function for desktop platform
PrintServiceInterface createPrintService() => DesktopPrintService();

/// Desktop implementation using flutter_thermal_printer
class DesktopPrintService implements PrintServiceInterface {
  final ThermalPrintService _thermalService = ThermalPrintService();

  @override
  List<PrinterInfo> get availablePrinters {
    return _thermalService.availablePrinters.map((p) => _toPrinterInfo(p)).toList();
  }

  @override
  PrinterInfo? get selectedPrinter {
    final printer = _thermalService.selectedPrinter;
    return printer != null ? _toPrinterInfo(printer) : null;
  }

  @override
  bool get isWebSerialSupported => false; // Not applicable on desktop

  @override
  Future<void> init() => _thermalService.init();

  @override
  Future<void> startScan({
    List<PrinterConnectionType> connectionTypes = const [
      PrinterConnectionType.usb,
      PrinterConnectionType.bluetooth,
      PrinterConnectionType.network,
    ],
  }) {
    // Convert to flutter_thermal_printer ConnectionType
    final nativeTypes = connectionTypes.map((t) {
      switch (t) {
        case PrinterConnectionType.usb:
          return ConnectionType.USB;
        case PrinterConnectionType.bluetooth:
          return ConnectionType.BLE;
        case PrinterConnectionType.network:
          return ConnectionType.NETWORK;
        case PrinterConnectionType.serial:
          return ConnectionType.USB; // Map serial to USB on desktop
      }
    }).toList();

    return _thermalService.startScan(connectionTypes: nativeTypes);
  }

  @override
  void stopScan() => _thermalService.stopScan();

  @override
  void selectPrinter(PrinterInfo printer) {
    if (printer.nativePrinter is Printer) {
      _thermalService.selectPrinter(printer.nativePrinter as Printer);
    }
  }

  @override
  Future<bool> connect() => _thermalService.connect();

  @override
  Future<void> disconnect() => _thermalService.disconnect();

  @override
  Future<bool> printReceipt(Order order, {bool autoCut = true}) {
    return _thermalService.printReceipt(order, autoCut: autoCut);
  }

  @override
  Future<bool> printRaw(List<int> data) async {
    // Direct raw printing through flutter_thermal_printer
    final printer = _thermalService.selectedPrinter;
    if (printer == null) return false;

    try {
      final connected = await connect();
      if (!connected) return false;

      await FlutterThermalPrinter.instance.printData(
        printer,
        data,
        longData: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() => _thermalService.dispose();

  /// Convert native Printer to PrinterInfo
  PrinterInfo _toPrinterInfo(Printer printer) {
    PrinterConnectionType connectionType;
    switch (printer.connectionType) {
      case ConnectionType.USB:
        connectionType = PrinterConnectionType.usb;
        break;
      case ConnectionType.BLE:
        connectionType = PrinterConnectionType.bluetooth;
        break;
      case ConnectionType.NETWORK:
        connectionType = PrinterConnectionType.network;
        break;
      default:
        connectionType = PrinterConnectionType.usb;
    }

    return PrinterInfo(
      name: printer.name ?? 'Unknown Printer',
      address: printer.address ?? '',
      connectionType: connectionType,
      nativePrinter: printer,
    );
  }
}
