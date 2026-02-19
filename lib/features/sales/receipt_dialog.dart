import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/cart.dart';
import '../../core/services/print_service_interface.dart';
import '../../core/services/print_service_factory.dart';
import '../../shared/constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';

class ReceiptDialog extends StatefulWidget {
  final Order order;

  const ReceiptDialog({super.key, required this.order});

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  late final PrintServiceInterface _printService;
  bool _isPrinting = false;
  bool _isScanning = false;
  String? _printMessage;

  @override
  void initState() {
    super.initState();
    _printService = PrintServiceFactory.getInstance();
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
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final order = widget.order;

    // Build payment info string (matches thermal print)
    String paymentInfo = 'Payment: ${_formatPaymentMethod(order.paymentMethod)}';
    if (order.cardLastFour != null) {
      paymentInfo += ' (*${order.cardLastFour})';
    }

    // Tax label with percentage
    String taxLabel = l10n?.tax ?? 'Tax';
    if (order.taxAmount > 0 && order.subTotal > 0) {
      final pct = (order.taxAmount / order.subTotal * 100).round();
      taxLabel = '${l10n?.tax ?? 'Tax'} ($pct%)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header - matches thermal print
        Text(
          AppConstants.appName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'POS Receipt',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Order info - left aligned, matches thermal print
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n?.orderNumber ?? 'Order'}: ${order.code}',
                  style: const TextStyle(fontSize: 13)),
              Text('${l10n?.date ?? 'Date'}: ${dateFormat.format(order.createdAt)}',
                  style: const TextStyle(fontSize: 13)),
              if (order.customer != null)
                Text('${l10n?.customer ?? 'Customer'}: ${order.customer!.name}',
                    style: const TextStyle(fontSize: 13)),
              Text(paymentInfo, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),

        const Divider(height: 24),

        // Column headers - matches thermal print
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(l10n?.item ?? 'Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              SizedBox(
                width: 40,
                child: Text(l10n?.qty ?? 'Qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(
                flex: 3,
                child: Text(l10n?.amount ?? 'Amount',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const Divider(height: 4),

        // Items - table format matching thermal print
        ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(item.name, style: const TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(item.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(AppCurrency.format(item.total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            )),

        const Divider(height: 24),

        // Subtotal (always show)
        _buildSummaryRow(l10n?.subtotal ?? 'Subtotal', AppCurrency.format(order.subTotal)),

        // Tax with percentage
        if (order.taxAmount > 0)
          _buildSummaryRow(taxLabel, AppCurrency.format(order.taxAmount)),

        // Discount
        if (order.discountAmount > 0)
          _buildSummaryRow(l10n?.discount ?? 'Discount', '-${AppCurrency.format(order.discountAmount)}'),

        const Divider(height: 16),

        // Total - bold, matches thermal print
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n?.total ?? 'TOTAL'}:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppCurrency.format(order.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Cash/Change details - matches thermal print
        if (order.cashReceived != null && order.changeGiven != null) ...[
          const SizedBox(height: 4),
          _buildSummaryRow(l10n?.cashReceived ?? 'Cash', AppCurrency.format(order.cashReceived!)),
          _buildSummaryRow(l10n?.change ?? 'Change', AppCurrency.format(order.changeGiven!)),
        ],

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Footer - matches thermal print
        Text(
          'Thank you for your purchase!',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          'Please come again',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
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

  Future<void> _printReceipt(PrinterInfo printer) async {
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
  final PrintServiceInterface printService;
  final Function(PrinterInfo) onPrinterSelected;

  const _PrinterSelectionDialog({
    required this.printService,
    required this.onPrinterSelected,
  });

  @override
  State<_PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<_PrinterSelectionDialog> {
  bool _isScanning = true;
  List<PrinterInfo> _printers = [];
  PrinterConnectionType _selectedConnectionType = PrinterConnectionType.usb;

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

  IconData _getConnectionIcon(PrinterConnectionType? type) {
    switch (type) {
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.network:
        return Icons.wifi;
      case PrinterConnectionType.serial:
        return Icons.settings_input_hdmi;
      default:
        return Icons.print;
    }
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
            SegmentedButton<PrinterConnectionType>(
              segments: const [
                ButtonSegment(
                  value: PrinterConnectionType.usb,
                  label: Text('USB'),
                  icon: Icon(Icons.usb),
                ),
                ButtonSegment(
                  value: PrinterConnectionType.bluetooth,
                  label: Text('Bluetooth'),
                  icon: Icon(Icons.bluetooth),
                ),
                ButtonSegment(
                  value: PrinterConnectionType.network,
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
                          title: Text(printer.name.isNotEmpty ? printer.name : 'Unknown Printer'),
                          subtitle: Text(
                            printer.address,
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
}
