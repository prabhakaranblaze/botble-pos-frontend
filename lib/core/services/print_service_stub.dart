import 'print_service_interface.dart';
import '../models/cart.dart';

/// Stub implementation - should never be used
PrintServiceInterface createPrintService() => _StubPrintService();

class _StubPrintService implements PrintServiceInterface {
  @override
  List<PrinterInfo> get availablePrinters => [];

  @override
  PrinterInfo? get selectedPrinter => null;

  @override
  bool get isWebSerialSupported => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> startScan({List<PrinterConnectionType> connectionTypes = const []}) async {}

  @override
  void stopScan() {}

  @override
  void selectPrinter(PrinterInfo printer) {}

  @override
  Future<bool> connect() async => false;

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> printReceipt(Order order, {bool autoCut = true}) async => false;

  @override
  Future<bool> printRaw(List<int> data) async => false;

  @override
  void dispose() {}
}
