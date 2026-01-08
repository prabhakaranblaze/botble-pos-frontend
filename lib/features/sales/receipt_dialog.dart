import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import '../../core/models/cart.dart';
import '../../core/services/thermal_print_service.dart';
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';

class ReceiptDialog extends StatefulWidget {
  final Order order;

  const ReceiptDialog({super.key, required this.order});

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  final ThermalPrintService _printService = ThermalPrintService();
  bool _isPrinting = false;
  bool _isScanning = false;
  String? _printMessage;

  @override
  void initState() {
    super.initState();
    _printService.init();
  }

  @override
  void dispose() {
    _printService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.success,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    l10n?.orderComplete ?? 'Order Complete!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Receipt Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildReceiptContent(),
              ),
            ),

            // Print status message
            if (_printMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _printMessage!,
                  style: TextStyle(
                    color: _printMessage!.contains('success')
                        ? AppColors.success
                        : _printMessage!.contains('Error')
                            ? AppColors.error
                            : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPrinting ? null : _showPrinterDialog,
                          icon: _isPrinting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.print),
                          label: Text(_isPrinting ? (l10n?.printing ?? 'Printing...') : (l10n?.printReceipt ?? 'Print')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(l10n?.done ?? 'Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptContent() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n?.orderNumber ?? 'Order'} ${widget.order.code}',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          dateFormat.format(widget.order.createdAt),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Divider(height: 32),

        // Items
        ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${item.quantity} x ${AppCurrency.format(item.price)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppCurrency.format(item.total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),

        const Divider(height: 32),

        // Subtotal
        if (widget.order.subTotal > 0)
          _buildSummaryRow(l10n?.subtotal ?? 'Subtotal', AppCurrency.format(widget.order.subTotal)),

        // Tax
        if (widget.order.taxAmount > 0)
          _buildSummaryRow(l10n?.tax ?? 'Tax', AppCurrency.format(widget.order.taxAmount)),

        // Discount
        if (widget.order.discountAmount > 0)
          _buildSummaryRow(l10n?.discount ?? 'Discount', '-${AppCurrency.format(widget.order.discountAmount)}'),

        const SizedBox(height: 8),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.total ?? 'Total',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              AppCurrency.format(widget.order.amount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Payment Method
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.paymentMethod ?? 'Payment Method',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                _formatPaymentMethod(widget.order.paymentMethod),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        if (widget.order.paymentDetails != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.order.paymentDetails!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    final l10n = AppLocalizations.of(context);
    switch (method.toLowerCase()) {
      case 'pos_cash':
      case 'cash':
        return l10n?.cash ?? 'Cash';
      case 'pos_card':
      case 'card':
        return l10n?.card ?? 'Card';
      default:
        return method.toUpperCase();
    }
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) => _PrinterSelectionDialog(
        printService: _printService,
        onPrinterSelected: (printer) {
          Navigator.pop(context);
          _printReceipt(printer);
        },
      ),
    );
  }

  Future<void> _printReceipt(Printer printer) async {
    setState(() {
      _isPrinting = true;
      _printMessage = 'Connecting to printer...';
    });

    try {
      _printService.selectPrinter(printer);

      setState(() {
        _printMessage = 'Printing receipt...';
      });

      final success = await _printService.printReceipt(widget.order, autoCut: true);

      setState(() {
        _isPrinting = false;
        _printMessage = success
            ? 'Print success!'
            : 'Error: Print failed. Please check printer connection.';
      });

      // Clear message after a delay
      if (success) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _printMessage = null;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isPrinting = false;
        _printMessage = 'Error: ${e.toString()}';
      });
    }
  }
}

/// Dialog to select a thermal printer
class _PrinterSelectionDialog extends StatefulWidget {
  final ThermalPrintService printService;
  final Function(Printer) onPrinterSelected;

  const _PrinterSelectionDialog({
    required this.printService,
    required this.onPrinterSelected,
  });

  @override
  State<_PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  bool _isScanning = true;
  List<Printer> _printers = [];
  ConnectionType _selectedConnectionType = ConnectionType.USB;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _printers = [];
    });

    widget.printService.startScan(
      connectionTypes: [_selectedConnectionType],
    );

    // Update printer list periodically
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _printers = widget.printService.availablePrinters;
          _isScanning = false;
        });
      }
    });

    // Keep scanning for a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _printers = widget.printService.availablePrinters;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n?.selectPrinter ?? 'Select Printer'),
      content: SizedBox(
        width: 350,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection type selector
            SegmentedButton<ConnectionType>(
              segments: const [
                ButtonSegment(
                  value: ConnectionType.USB,
                  label: Text('USB'),
                  icon: Icon(Icons.usb),
                ),
                ButtonSegment(
                  value: ConnectionType.BLE,
                  label: Text('Bluetooth'),
                  icon: Icon(Icons.bluetooth),
                ),
                ButtonSegment(
                  value: ConnectionType.NETWORK,
                  label: Text('WiFi'),
                  icon: Icon(Icons.wifi),
                ),
              ],
              selected: {_selectedConnectionType},
              onSelectionChanged: (types) {
                setState(() {
                  _selectedConnectionType = types.first;
                });
                _startScan();
              },
            ),
            const SizedBox(height: 16),

            // Scan status
            if (_isScanning)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n?.loading ?? 'Scanning for printers...'),
                  ],
                ),
              ),

            // Printer list
            Expanded(
              child: _printers.isEmpty && !_isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.print_disabled,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.noResults ?? 'No printers found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _startScan,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n?.refresh ?? 'Scan Again'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _printers.length,
                      itemBuilder: (context, index) {
                        final printer = _printers[index];
                        return ListTile(
                          leading: Icon(
                            _getConnectionIcon(printer.connectionType),
                            color: AppColors.primary,
                          ),
                          title: Text(printer.name ?? 'Unknown Printer'),
                          subtitle: Text(
                            printer.address ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onPrinterSelected(printer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        TextButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.refresh),
          label: Text(l10n?.refresh ?? 'Refresh'),
        ),
      ],
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
