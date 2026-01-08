import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/model/order.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:martfury/src/view/widget/order_cancellation_dialog.dart';
import 'package:martfury/src/view/screen/product_detail_screen.dart';
import 'package:martfury/src/view/screen/pdf_invoice_viewer_screen.dart';
import 'package:martfury/src/view/screen/proof_viewer_screen.dart';
import 'package:martfury/src/service/product_service.dart';
import 'package:martfury/core/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingProof = false;
  bool _isDownloadingProof = false;
  bool _hasUploadedProof = false;
  bool _isLoadingInvoice = false;
  bool _isDownloadingInvoice = false;
  bool _isViewingProof = false;
  Map<String, dynamic>? _paymentProofInfo;
  Order? _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _checkIfProofUploaded();
  }

  Future<void> _checkIfProofUploaded() async {
    if (!_canUploadProof()) return;

    try {
      // Get order details to check for payment_proof field
      final orderDetails = await _orderService.getOrderDetails(_currentOrder!.id);


      // Check if the new payment_proof field exists
      if (orderDetails['data'] != null && orderDetails['data']['payment_proof'] != null) {
        final paymentProof = orderDetails['data']['payment_proof'];

        // Check if proof exists and has required fields
        if (paymentProof['has_proof'] == true &&
            paymentProof['download_url'] != null &&
            paymentProof['download_url'].toString().isNotEmpty) {

          setState(() {
            _hasUploadedProof = true;
            _paymentProofInfo = Map<String, dynamic>.from(paymentProof);
          });

          return;
        }
      }

      // If no payment_proof field or has_proof is false, no proof exists
      setState(() {
        _hasUploadedProof = false;
        _paymentProofInfo = null;
      });

    } catch (e) {
      // Fallback to old method if new API structure doesn't exist
      try {
        await _orderService.downloadPaymentProof(orderId: _currentOrder!.id);
        setState(() {
          _hasUploadedProof = true;
          _paymentProofInfo = null; // No detailed info available
        });
      } catch (e2) {
        setState(() {
          _hasUploadedProof = false;
          _paymentProofInfo = null;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFB800);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'canceled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orders.status_pending'.tr();
      case 'processing':
        return 'orders.status_processing'.tr();
      case 'completed':
        return 'orders.status_completed'.tr();
      case 'canceled':
        return 'orders.status_cancelled'.tr();
      default:
        return status;
    }
  }

  void _copyOrderNumber() {
    Clipboard.setData(ClipboardData(text: _currentOrder!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('orders.order_number_copied'.tr()),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _canCancelOrder() {
    final status = _currentOrder!.status.value.toLowerCase();
    return status == 'pending' || status == 'processing';
  }

  bool _canUploadProof() {
    if (!AppConfig.enableOrderUploadProof) {
      return false;
    }

    final status = _currentOrder!.status.value.toLowerCase();
    final paymentStatus = _currentOrder!.paymentStatus.value.toLowerCase();


    // Be more permissive with payment status - allow if not completed/paid
    bool canUpload = (status == 'pending' || status == 'processing') &&
                     (paymentStatus != 'completed' && paymentStatus != 'paid' && paymentStatus != 'success');

    return canUpload;
  }

  Future<void> _showFileTypeDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select File Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF2196F3)),
                title: const Text('Select Image'),
                subtitle: const Text('JPG, PNG formats'),
                onTap: () => Navigator.of(context).pop('image'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFF44336)),
                title: const Text('Select PDF'),
                subtitle: const Text('PDF documents'),
                onTap: () => Navigator.of(context).pop('pdf'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('common.cancel'.tr()),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (result == 'image') {
        await _selectImage();
      } else if (result == 'pdf') {
        await _selectPdf();
      }
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      final file = File(image.path);
      await _uploadFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: ${e.toString()}'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  Future<void> _selectPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Change to any type to avoid iOS issues
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      
      // Check if it's a PDF
      if (!file.path.toLowerCase().endsWith('.pdf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a PDF file'),
              backgroundColor: Color(0xFFF44336),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      await _uploadFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select PDF: ${e.toString()}'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      // Check file size (5MB limit)
      final fileSize = await file.length();

      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('orders.proof_file_size_limit'.tr()),
              backgroundColor: const Color(0xFFF44336),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploadingProof = true;
      });

      // Test if we can access the order first
      await _orderService.testUploadProofEndpoint(_currentOrder!.id);

      await _orderService.uploadPaymentProof(
        orderId: _currentOrder!.id,
        proofFile: file,
      );

      if (mounted) {
        setState(() {
          _isUploadingProof = false;
          _hasUploadedProof = true; // Mark as uploaded
        });

        // Refresh proof info to get the latest details
        _checkIfProofUploaded();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('orders.proof_uploaded_successfully'.tr()),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingProof = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _uploadPaymentProof() async {
    await _showFileTypeDialog();
  }

  Future<void> _downloadPaymentProof() async {
    setState(() {
      _isDownloadingProof = true;
    });

    try {
      // Get proof data stream
      final stream = await _orderService.streamPaymentProof(_currentOrder!.id);
      
      // Collect stream data
      final List<int> bytes = [];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
      
      if (bytes.isNotEmpty) {
        final proofData = Uint8List.fromList(bytes);
        
        // Save file with appropriate name
        final file = await _orderService.savePdfToFile(
          proofData, 
          _currentOrder!.id,
          prefix: 'proof-${_currentOrder!.code}',
        );
        
        // Share the file so user can save it
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Payment Proof for Order ${_currentOrder!.code}',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('orders.proof_downloaded_successfully'.tr()),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to download proof file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloadingProof = false;
      });
    }
  }

  Future<void> _viewPaymentProof() async {
    try {
      setState(() {
        _isViewingProof = true;
      });

      // Navigate to the dedicated proof viewer screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProofViewerScreen(
              orderId: _currentOrder!.id,
              orderCode: _currentOrder!.code,
              proofInfo: _paymentProofInfo,
            ),
          ),
        );
      }

      setState(() {
        _isViewingProof = false;
      });
    } catch (e) {
      setState(() {
        _isViewingProof = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _replacePaymentProof() async {
    // Show confirmation dialog first
    final bool? shouldReplace = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('orders.replace_payment_proof'.tr()),
          content: Text('orders.replace_proof_confirmation'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                elevation: 0,
              ),
              child: Text(
                'orders.replace_proof'.tr(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldReplace == true) {
      // Proceed with upload (same as regular upload)
      await _uploadPaymentProof();
    }
  }

  String _formatUploadDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderCancellationDialog(
        onConfirm: _cancelOrder,
      ),
    );
  }

  Future<void> _cancelOrder(String reason, String? description) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _orderService.cancelOrder(
        orderId: _currentOrder!.id,
        cancellationReason: reason,
        cancellationReasonDescription: description,
      );

      // Update the order status locally
      setState(() {
        _currentOrder = Order(
          id: _currentOrder!.id,
          code: _currentOrder!.code,
          status: OrderStatus(value: 'canceled', label: 'Cancelled'),
          statusHtml: _currentOrder!.statusHtml,
          customer: _currentOrder!.customer,
          createdAt: _currentOrder!.createdAt,
          amount: _currentOrder!.amount,
          amountFormatted: _currentOrder!.amountFormatted,
          taxAmount: _currentOrder!.taxAmount,
          taxAmountFormatted: _currentOrder!.taxAmountFormatted,
          shippingAmount: _currentOrder!.shippingAmount,
          shippingAmountFormatted: _currentOrder!.shippingAmountFormatted,
          shippingMethod: _currentOrder!.shippingMethod,
          shippingStatus: _currentOrder!.shippingStatus,
          shippingStatusHtml: _currentOrder!.shippingStatusHtml,
          paymentMethod: _currentOrder!.paymentMethod,
          paymentStatus: _currentOrder!.paymentStatus,
          paymentStatusHtml: _currentOrder!.paymentStatusHtml,
          productsCount: _currentOrder!.productsCount,
          products: _currentOrder!.products,
        );
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('orders.order_cancelled_successfully'.tr()),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _getRelativeDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'orders.time_days_ago_single'.tr();
      } else {
        return 'orders.time_days_ago_multiple'.tr(
          namedArgs: {'count': difference.inDays.toString()},
        );
      }
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) {
        return 'orders.time_hours_ago_single'.tr();
      } else {
        return 'orders.time_hours_ago_multiple'.tr(
          namedArgs: {'count': difference.inHours.toString()},
        );
      }
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) {
        return 'orders.time_minutes_ago_single'.tr();
      } else {
        return 'orders.time_minutes_ago_multiple'.tr(
          namedArgs: {'count': difference.inMinutes.toString()},
        );
      }
    } else {
      return 'orders.time_just_now'.tr();
    }
  }

  Future<void> _viewInvoice() async {
    try {
      setState(() {
        _isLoadingInvoice = true;
      });


      // Navigate to the dedicated PDF viewer screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfInvoiceViewerScreen(
              orderId: _currentOrder!.id,
              orderCode: _currentOrder!.code,
            ),
          ),
        );
      }

      setState(() {
        _isLoadingInvoice = false;
      });
    } catch (e) {

      setState(() {
        _isLoadingInvoice = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _downloadInvoice() async {
    try {
      setState(() {
        _isDownloadingInvoice = true;
      });

      // Download the PDF content
      final pdfBytes = await _orderService.downloadInvoicePdf(_currentOrder!.id, type: 'download');
      
      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        // Save to file
        final file = await _orderService.savePdfToFile(pdfBytes, _currentOrder!.id);
        
        // Share the file so user can save it
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Invoice for Order ${_currentOrder!.code}',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('orders.invoice_downloaded'.tr()),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfInvoiceViewerScreen(
                        orderId: _currentOrder!.id,
                        orderCode: _currentOrder!.code,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to download invoice PDF');
      }

      setState(() {
        _isDownloadingInvoice = false;
      });
    } catch (e) {
      setState(() {
        _isDownloadingInvoice = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  bool _canViewInvoice() {
    // Invoice is typically available for all orders except cancelled ones
    final status = _currentOrder!.status.value.toLowerCase();
    return status != 'canceled';
  }

  Future<void> _navigateToProduct(dynamic product) async {
    final productId = product['product_id'];
    final productSlug = product['product_slug'];
    final productName = product['product_name'] ?? 'N/A';
    final productImage = product['product_image'] ?? '';

    if (productSlug != null && productSlug.isNotEmpty) {
      // Add to recently viewed before navigation
      await ProductService.addToRecentlyViewed({
        'id': productId,
        'slug': productSlug,
        'image': productImage,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: {'slug': productSlug},
            ),
          ),
        );
      }
    } else {
      // Show a message if product slug is not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$productName" is no longer available'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentOrder == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final statusColor = _getStatusColor(_currentOrder!.status.value);
    final statusIcon = _getStatusIcon(_currentOrder!.status.value);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'orders.order_details'.tr(),
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Order Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.1),
                    statusColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(_currentOrder!.status.value),
                              style: kAppTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order ${_currentOrder!.code}',
                              style: kAppTextStyle(
                                fontSize: 14,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: _copyOrderNumber,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOrderProgress(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Information Card
            _buildSectionCard(
              title: 'orders.order_information'.tr(),
              icon: Icons.receipt_long,
              child: Column(
                children: [
                  _buildInfoRow(
                    'orders.order_number_label'.tr(),
                    _currentOrder!.code,
                    icon: Icons.tag,
                  ),
                  _buildInfoRow(
                    'orders.order_date_label'.tr(),
                    _getRelativeDate(_currentOrder!.createdAt),
                    icon: Icons.calendar_today,
                  ),
                  _buildInfoRow(
                    'orders.tax_amount_label'.tr(),
                    _currentOrder!.taxAmountFormatted,
                    icon: Icons.account_balance,
                  ),
                  _buildInfoRow(
                    'orders.shipping_amount_label'.tr(),
                    _currentOrder!.shippingAmountFormatted,
                    icon: Icons.local_shipping,
                  ),
                  _buildInfoRow(
                    'orders.total_amount_label'.tr(),
                    _currentOrder!.amountFormatted,
                    icon: Icons.attach_money,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Invoice Card
            if (_canViewInvoice()) ...[
              _buildSectionCard(
                title: 'orders.invoice'.tr(),
                icon: Icons.receipt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View your invoice in PDF format streamed directly from the API, or download it for record keeping and accounting purposes.',
                      style: kAppTextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingInvoice ? null : _viewInvoice,
                            icon: _isLoadingInvoice
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.getPrimaryTextColor(context),
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.visibility),
                            label: Text(
                              _isLoadingInvoice
                                  ? 'orders.invoice_loading'.tr()
                                  : 'View PDF',
                              style: kAppTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(
                                color: AppColors.getBorderColor(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDownloadingInvoice ? null : _downloadInvoice,
                            icon: _isDownloadingInvoice
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.download, color: Colors.black),
                            label: Text(
                              _isDownloadingInvoice
                                  ? 'common.downloading'.tr()
                                  : 'Download PDF',
                              style: kAppTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB800),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Customer Information Card
            _buildSectionCard(
              title: 'orders.customer_information'.tr(),
              icon: Icons.person,
              child: Column(
                children: [
                  _buildInfoRow(
                    'orders.customer_name'.tr(),
                    _currentOrder!.customer.name,
                    icon: Icons.person_outline,
                  ),
                  _buildInfoRow(
                    'common.email'.tr(),
                    _currentOrder!.customer.email,
                    icon: Icons.email_outlined,
                  ),
                  _buildInfoRow(
                    'orders.customer_phone'.tr(),
                    _currentOrder!.customer.phone,
                    icon: Icons.phone_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Information Card
            _buildSectionCard(
              title: 'orders.shipping_information'.tr(),
              icon: Icons.local_shipping,
              child: Column(
                children: [
                  _buildInfoRow(
                    'orders.shipping_method'.tr(),
                    _currentOrder!.shippingMethod.label,
                    icon: Icons.local_shipping_outlined,
                  ),
                  _buildInfoRow(
                    'orders.shipping_status'.tr(),
                    _currentOrder!.shippingStatus.label,
                    icon: Icons.track_changes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Information Card
            _buildSectionCard(
              title: 'orders.payment_information'.tr(),
              icon: Icons.payment,
              child: Column(
                children: [
                  _buildInfoRow(
                    'orders.payment_method'.tr(),
                    _currentOrder!.paymentMethod.label,
                    icon: Icons.credit_card,
                  ),
                  _buildInfoRow(
                    'orders.payment_status'.tr(),
                    _currentOrder!.paymentStatus.label,
                    icon: Icons.account_balance_wallet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Upload/Manage Payment Proof Card
            if (_canUploadProof()) ...[
              _buildSectionCard(
                title: _hasUploadedProof
                    ? 'orders.payment_proof'.tr()
                    : 'orders.upload_payment_proof'.tr(),
                icon: _hasUploadedProof ? Icons.receipt : Icons.upload_file,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_hasUploadedProof) ...[
                      // Initial upload section
                      Text(
                        'orders.upload_proof_description'.tr(),
                        style: kAppTextStyle(
                          fontSize: 14,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploadingProof ? null : _uploadPaymentProof,
                              icon: _isUploadingProof
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.upload, color: Colors.black),
                              label: Text(
                                _isUploadingProof
                                    ? 'common.uploading'.tr()
                                    : 'orders.select_proof_file'.tr(),
                                style: kAppTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB800),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Color(0xFF1976D2),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'orders.proof_file_size_limit'.tr(),
                                    style: kAppTextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF1976D2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Text(
                                'Supported formats: JPG, PNG, PDF',
                                style: kAppTextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF1976D2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Proof uploaded - show download and replace options
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'orders.proof_already_uploaded'.tr(),
                                    style: kAppTextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Show detailed info if available from new API
                            if (_paymentProofInfo != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_paymentProofInfo!['file_name'] != null) ...[
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.insert_drive_file,
                                            size: 16,
                                            color: Color(0xFF666666),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _paymentProofInfo!['file_name'].toString(),
                                              style: kAppTextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF333333),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_paymentProofInfo!['file_size'] != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.storage,
                                            size: 16,
                                            color: Color(0xFF666666),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _paymentProofInfo!['file_size'].toString(),
                                            style: kAppTextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_paymentProofInfo!['uploaded_at'] != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            size: 16,
                                            color: Color(0xFF666666),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatUploadDate(_paymentProofInfo!['uploaded_at'].toString()),
                                            style: kAppTextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isViewingProof ? null : _viewPaymentProof,
                              icon: _isViewingProof
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.getPrimaryTextColor(context),
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.visibility),
                              label: Text(
                                _isViewingProof
                                    ? 'Loading...'
                                    : 'View',
                                style: kAppTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(
                                  color: AppColors.getBorderColor(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isDownloadingProof ? null : _downloadPaymentProof,
                              icon: _isDownloadingProof
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.black,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.download, color: Colors.black),
                              label: Text(
                                _isDownloadingProof
                                    ? 'common.downloading'.tr()
                                    : 'Download',
                                style: kAppTextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB800),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _isUploadingProof ? null : _replacePaymentProof,
                          icon: _isUploadingProof
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey,
                                    ),
                                  ),
                                )
                              : Icon(Icons.refresh, color: AppColors.getSecondaryTextColor(context)),
                          label: Text(
                            _isUploadingProof
                                ? 'common.uploading'.tr()
                                : 'orders.replace_proof'.tr(),
                            style: kAppTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: AppColors.getSecondaryTextColor(context).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Products Card
            _buildSectionCard(
              title: 'orders.products'.tr(),
              icon: Icons.shopping_bag,
              child:
                  _currentOrder!.products.isNotEmpty
                      ? Column(
                        children:
                            _currentOrder!.products
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          entry.key <
                                                  _currentOrder!.products.length -
                                                      1
                                              ? 16
                                              : 0,
                                    ),
                                    child: _buildProductItem(entry.value),
                                  ),
                                )
                                .toList(),
                      )
                      : Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'orders.no_products_in_order'.tr(),
                              style: kAppTextStyle(
                                fontSize: 16,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            const SizedBox(height: 24),

            // Cancel Order Button at bottom
            if (_canCancelOrder())
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: _isLoading ? null : _showCancelOrderDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.getSecondaryTextColor(context).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                        )
                      : Text(
                          'orders.cancel_order'.tr(),
                          style: kAppTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                ),
              ),
            if (_canCancelOrder()) const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProgress() {
    final statuses = ['pending', 'processing', 'completed'];
    final currentStatus = _currentOrder!.status.value.toLowerCase();

    // If order is cancelled, don't show progress
    if (currentStatus == 'canceled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFF44336).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel,
              color: Color(0xFFF44336),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'orders.status_cancelled'.tr(),
              style: kAppTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF44336),
              ),
            ),
          ],
        ),
      );
    }

    final currentStatusIndex = statuses.indexOf(currentStatus);

    return Row(
      children:
          statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isActive = index <= currentStatusIndex;
            final isCurrent = index == currentStatusIndex;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? _getStatusColor(_currentOrder!.status.value)
                                    : AppColors.getBorderColor(context),
                            shape: BoxShape.circle,
                            border:
                                isCurrent
                                    ? Border.all(
                                      color: _getStatusColor(
                                        _currentOrder!.status.value,
                                      ),
                                      width: 3,
                                    )
                                    : null,
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: isActive ? Colors.white : AppColors.getSecondaryTextColor(context),
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStatusText(status),
                          style: kAppTextStyle(
                            fontSize: 12,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color:
                                isActive
                                    ? _getStatusColor(_currentOrder!.status.value)
                                    : AppColors.getSecondaryTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (index < statuses.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                            index < currentStatusIndex
                                ? _getStatusColor(_currentOrder!.status.value)
                                : AppColors.getBorderColor(context),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: kAppTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.getSecondaryTextColor(context)),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: kAppTextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(context),
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: kAppTextStyle(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? AppColors.primary : AppColors.getPrimaryTextColor(context),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(dynamic product) {
    final String imageUrl = product['product_image'] ?? '';
    final String productName = product['product_name'] ?? 'N/A';
    final String attributes = product['attributes']?.toString() ?? '';
    final int quantity = product['quantity'] ?? 0;
    final String amountFormatted = product['amount_formatted'] ?? 'N/A';
    final String totalFormatted = product['total_formatted'] ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: InkWell(
        onTap: () => _navigateToProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.getCardBackgroundColor(context),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getSkeletonColor(context).withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: AppColors.getSkeletonColor(context),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 32,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            ),
                      )
                      : Container(
                        color: AppColors.getSkeletonColor(context),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 16),
          // Enhanced Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        style: kAppTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getPrimaryTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.getSecondaryTextColor(context).withValues(alpha: 0.6),
                    ),
                  ],
                ),
                if (attributes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue[900]!.withValues(alpha: 0.2)
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      attributes,
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]
                            : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildProductDetailChip(
                      'orders.quantity_label'.tr(),
                      quantity.toString(),
                      Icons.inventory_2_outlined,
                    ),
                    _buildProductDetailChip(
                      'orders.price_label'.tr(),
                      amountFormatted,
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calculate,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${'orders.total_label'.tr()}: $totalFormatted',
                        style: kAppTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildProductDetailChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.getSecondaryTextColor(context)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $value',
              style: kAppTextStyle(
                fontSize: 12,
                color: AppColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
