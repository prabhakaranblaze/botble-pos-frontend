import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:martfury/core/app_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class ProofViewerScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final Map<String, dynamic>? proofInfo;

  const ProofViewerScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    this.proofInfo,
  });

  @override
  State<ProofViewerScreen> createState() => _ProofViewerScreenState();
}

class _ProofViewerScreenState extends State<ProofViewerScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  double _downloadProgress = 0.0;
  String? _fileName;
  String? _fileSize;
  bool _proofAvailable = false;
  Uint8List? _fileBytes;
  String? _imageUrl;
  bool _isImage = false;
  String? _pdfFilePath;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.proofInfo != null) {
      _fileName = widget.proofInfo!['file_name']?.toString();
      _fileSize = widget.proofInfo!['file_size']?.toString();
      _detectFileType();
    }
    _loadProofFile();
  }

  void _detectFileType() {
    if (_fileName != null) {
      final extension = _fileName!.toLowerCase();
      _isImage = extension.endsWith('.jpg') || 
                 extension.endsWith('.jpeg') || 
                 extension.endsWith('.png') ||
                 extension.endsWith('.gif') ||
                 extension.endsWith('.webp');
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


  Future<void> _loadProofFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
    });

    try {
      // For images, try to get the direct URL first
      if (_isImage && widget.proofInfo != null && widget.proofInfo!['download_url'] != null) {
        String imageUrl = widget.proofInfo!['download_url'].toString();
        
        // Make URL absolute if it's relative
        if (imageUrl.startsWith('/')) {
          imageUrl = '${AppConfig.apiBaseUrl}$imageUrl';
        }
        
        setState(() {
          _imageUrl = imageUrl;
          _proofAvailable = true;
          _isLoading = false;
          _downloadProgress = 1.0;
        });
        return;
      }

      // Otherwise, try streaming the file
      final stream = await _orderService.streamPaymentProof(
        widget.orderId,
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
        final fileData = Uint8List.fromList(bytes);
        
        if (_isImage) {
          setState(() {
            _fileBytes = fileData;
            _proofAvailable = true;
            _isLoading = false;
            _downloadProgress = 1.0;
          });
        } else {
          // For PDF files, verify it's valid PDF data
          if (!_isPdfData(fileData)) {
            throw Exception('Invalid PDF data received: Not a valid PDF file');
          }
          
          // Save to temporary file for PDF viewer
          final file = await _orderService.savePdfToFile(fileData, widget.orderId, prefix: 'proof');
          
          setState(() {
            _fileBytes = fileData;
            _pdfFilePath = file.path;
            _proofAvailable = true;
            _isLoading = false;
            _downloadProgress = 1.0;
          });
        }
      } else {
        throw Exception('No data received from server');
      }
    } catch (e) {
      // If streaming fails for images, fall back to using download URL
      if (_isImage) {
        try {
          String downloadUrl = await _orderService.downloadPaymentProof(
            orderId: widget.orderId,
          );
          
          setState(() {
            _imageUrl = downloadUrl;
            _proofAvailable = true;
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        } catch (e2) {
          // Continue with error handling
        }
      }
      
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  Future<void> _downloadProof() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      Uint8List? proofData = _fileBytes;
      
      // If we don't have the file bytes yet, download them
      if (proofData == null) {
        // Get proof data stream
        final stream = await _orderService.streamPaymentProof(widget.orderId);
        
        // Collect stream data
        final List<int> bytes = [];
        await for (final chunk in stream) {
          bytes.addAll(chunk);
        }
        
        if (bytes.isNotEmpty) {
          proofData = Uint8List.fromList(bytes);
        } else {
          throw Exception('Failed to download proof file');
        }
      }
      
      if (proofData.isNotEmpty) {
        // Save file with appropriate name
        final file = await _orderService.savePdfToFile(
          proofData, 
          widget.orderId,
          prefix: 'proof-${widget.orderCode}',
        );
        
        // Share the file so user can save it
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Payment Proof for Order ${widget.orderCode}',
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
        _isDownloading = false;
      });
    }
  }

  Future<void> _shareProof() async {
    try {
      // If we have the file bytes (PDF or image), share as file
      if (_fileBytes != null) {
        final file = await _orderService.savePdfToFile(
          _fileBytes!,
          widget.orderId,
          prefix: 'proof',
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Payment Proof for Order ${widget.orderCode}',
          ),
        );
        return;
      }

      // Otherwise share the URL
      String downloadUrl = '';

      // Use download_url from proof info if available
      if (widget.proofInfo != null && widget.proofInfo!['download_url'] != null) {
        downloadUrl = widget.proofInfo!['download_url'].toString();
        
        // Make URL absolute if it's relative
        if (downloadUrl.startsWith('/')) {
          downloadUrl = '${AppConfig.apiBaseUrl}$downloadUrl';
        }
      } else {
        // Fallback to getting download URL from service
        downloadUrl = await _orderService.downloadPaymentProof(
          orderId: widget.orderId,
        );
      }

      await SharePlus.instance.share(
        ShareParams(
          text: downloadUrl,
          subject: 'Payment Proof for Order ${widget.orderCode}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share proof: $e'),
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
          '${'orders.payment_proof'.tr()} - ${widget.orderCode}',
          style: kAppTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareProof,
            tooltip: 'Share Proof',
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
            onPressed: _isDownloading ? null : _downloadProof,
            tooltip: 'orders.download_proof'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadProofFile,
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
              'Loading payment proof...',
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
                'Error loading proof',
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
              Text(
                'Note: Direct viewing may not be available. Try downloading the file instead.',
                textAlign: TextAlign.center,
                style: kAppTextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryTextColor(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadProofFile,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'common.retry'.tr(),
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _downloadProof,
                    icon: const Icon(Icons.download, color: Colors.black),
                    label: Text(
                      'Download Instead',
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
            ],
          ),
        ),
      );
    }

    // Success state - show file info
    if (_proofAvailable || (!_isLoading && _errorMessage == null)) {
      // Show image viewer for image files
      if (_isImage && (_imageUrl != null || _fileBytes != null)) {
        return _buildImageViewer();
      }
      
      // Show PDF viewer for PDF files
      if (!_isImage && _pdfFilePath != null) {
        return _buildPdfViewer();
      }
      
      // Show file info for other files
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isImage ? Icons.image : Icons.picture_as_pdf,
                  size: 80,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Proof Available',
                style: kAppTextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getPrimaryTextColor(context),
                ),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 8),
                Text(
                  _fileName!,
                  style: kAppTextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
              if (_fileSize != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Size: $_fileSize',
                  style: kAppTextStyle(
                    fontSize: 12,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.getBorderColor(context)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.getSecondaryTextColor(context),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment proof file is ready. Use the action buttons above to download, share, or open in browser.',
                      textAlign: TextAlign.center,
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback
    return const SizedBox.shrink();
  }

  Widget _buildImageViewer() {
    if (_imageUrl != null) {
      // Load from URL
      return Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(_imageUrl!),
            backgroundDecoration: BoxDecoration(
              color: AppColors.getBackgroundColor(context),
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            initialScale: PhotoViewComputedScale.contained,
            loadingBuilder: (context, event) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  if (event != null)
                    Text(
                      '${((event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1)) * 100).toInt()}%',
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                    ),
                ],
              ),
            ),
            errorBuilder: (context, error, stackTrace) => Center(
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
                    'Failed to load image',
                    style: kAppTextStyle(
                      fontSize: 16,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadProofFile,
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    label: Text(
                      'Retry',
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
          ),
          // File info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_fileName != null)
                    Text(
                      _fileName!,
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  if (_fileSize != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Size: $_fileSize',
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Pinch to zoom • Double tap to zoom',
                    style: kAppTextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_fileBytes != null) {
      // Load from bytes
      return Stack(
        children: [
          PhotoView(
            imageProvider: MemoryImage(_fileBytes!),
            backgroundDecoration: BoxDecoration(
              color: AppColors.getBackgroundColor(context),
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            initialScale: PhotoViewComputedScale.contained,
          ),
          // File info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_fileName != null)
                    Text(
                      _fileName!,
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  if (_fileSize != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Size: $_fileSize',
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Pinch to zoom • Double tap to zoom',
                    style: kAppTextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildPdfViewer() {
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
        // File info overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(179), // 0.7 * 255 = 179
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_fileName != null)
                    Text(
                      _fileName!,
                      style: kAppTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  if (_fileSize != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Size: $_fileSize',
                      style: kAppTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}