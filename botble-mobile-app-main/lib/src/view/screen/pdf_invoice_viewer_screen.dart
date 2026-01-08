import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfInvoiceViewerScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;

  const PdfInvoiceViewerScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  State<PdfInvoiceViewerScreen> createState() => _PdfInvoiceViewerScreenState();
}

class _PdfInvoiceViewerScreenState extends State<PdfInvoiceViewerScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  bool _isDownloading = false;
  Uint8List? _pdfBytes;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  String? _pdfFilePath;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdfInvoice();
  }

  Future<void> _loadPdfInvoice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
    });

    try {
      // Get PDF stream from API
      final stream = await _orderService.streamInvoicePdf(
        widget.orderId,
        type: 'print',
      );

      // Collect stream data
      final List<int> bytes = [];
      int totalBytes = 0;

      await for (final chunk in stream) {
        bytes.addAll(chunk);
        totalBytes += chunk.length;

        // Update progress (approximate)
        setState(() {
          _downloadProgress =
              totalBytes / (totalBytes + 1000); // Rough estimate
        });
      }

      if (bytes.isNotEmpty) {
        final pdfData = Uint8List.fromList(bytes);

        // Verify it's PDF data
        if (_isPdfData(pdfData)) {
          // Save to temporary file for PDF viewer
          final file = await _orderService.savePdfToFile(pdfData, widget.orderId);
          
          setState(() {
            _pdfBytes = pdfData;
            _pdfFilePath = file.path;
            _isLoading = false;
            _downloadProgress = 1.0;
          });
        } else {
          throw Exception('Invalid PDF data received from server');
        }
      } else {
        throw Exception('No data received from server');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  bool _isPdfData(Uint8List data) {
    // Check PDF magic number
    if (data.length < 4) return false;
    return data[0] == 0x25 &&
        data[1] == 0x50 &&
        data[2] == 0x44 &&
        data[3] == 0x46; // %PDF
  }

  Future<void> _downloadInvoice() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      Uint8List? pdfData = _pdfBytes;
      
      // If we don't have the PDF bytes yet, download them
      pdfData ??= await _orderService.downloadInvoicePdf(widget.orderId, type: 'download');
      
      if (pdfData != null && pdfData.isNotEmpty) {
        // Save PDF to file
        final file = await _orderService.savePdfToFile(pdfData, widget.orderId);
        
        // Share the file so user can save it
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Invoice for Order ${widget.orderCode}',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('orders.invoice_downloaded'.tr()),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to download invoice PDF');
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
        _isDownloading = false;
      });
    }
  }

  Future<void> _shareInvoice() async {
    try {
      if (_pdfBytes != null) {
        // Save PDF and share file
        final file = await _orderService.savePdfToFile(
          _pdfBytes!,
          widget.orderId,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Invoice for Order ${widget.orderCode}',
          ),
        );
      } else {
        // Download and share the PDF
        final pdfData = await _orderService.downloadInvoicePdf(widget.orderId);
        if (pdfData != null && pdfData.isNotEmpty) {
          final file = await _orderService.savePdfToFile(pdfData, widget.orderId);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              subject: 'Invoice for Order ${widget.orderCode}',
            ),
          );
        } else {
          throw Exception('Failed to download invoice for sharing');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share invoice: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          '${'orders.invoice'.tr()} ${widget.orderCode}',
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              onPressed: _shareInvoice,
              tooltip: 'Share Invoice',
            ),
            IconButton(
              icon:
                  _isDownloading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                      : const Icon(Icons.download, color: Colors.black),
              onPressed: _isDownloading ? null : _downloadInvoice,
              tooltip: 'orders.download_invoice'.tr(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadPdfInvoice,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'orders.invoice_loading'.tr(),
              style: kAppTextStyle(
                fontSize: 16,
                color: AppColors.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            if (_downloadProgress > 0) ...[
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toInt()}%',
                style: kAppTextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.getSecondaryTextColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading invoice',
                style: kAppTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: kAppTextStyle(
                  fontSize: 14,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPdfInvoice,
                icon: const Icon(Icons.refresh, color: Colors.black),
                label: Text(
                  'common.retry'.tr(),
                  style: kAppTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfFilePath != null) {
      return Stack(
        children: [
          PDFView(
            filePath: _pdfFilePath!,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                _errorMessage = 'Error on page $page: $error';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // PDF view controller is ready
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page ?? 0;
                _totalPages = total ?? 0;
              });
            },
          ),
          // Page indicator
          if (_totalPages > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(179), // 0.7 * 255 = 179
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Center(
      child: Text(
        'orders.invoice_not_available'.tr(),
        style: kAppTextStyle(
          fontSize: 16,
          color: AppColors.getSecondaryTextColor(context),
        ),
      ),
    );
  }
}
