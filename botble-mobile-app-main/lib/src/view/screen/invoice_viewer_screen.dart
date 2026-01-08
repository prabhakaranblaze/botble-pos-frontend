import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:martfury/src/service/order_service.dart';
import 'package:martfury/src/theme/app_fonts.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceViewerScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;

  const InvoiceViewerScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
  });

  @override
  State<InvoiceViewerScreen> createState() => _InvoiceViewerScreenState();
}

class _InvoiceViewerScreenState extends State<InvoiceViewerScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _invoiceUrl;
  Map<String, String>? _headers;
  String? _errorMessage;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First try to get a pre-authenticated URL
      final url = await _orderService.getInvoiceUrl(
        widget.orderId,
        type: 'print',
      );

      if (url != null && url.isNotEmpty) {
        setState(() {
          _invoiceUrl = url;
          _isLoading = false;
        });

        // Initialize WebView controller with the URL
        _initializeWebView();
      } else {
        // Fallback: try to get URL with headers
        await _loadInvoiceWithHeaders();
      }
    } catch (e) {
      // Fallback: try to get URL with headers
      await _loadInvoiceWithHeaders();
    }
  }

  Future<void> _loadInvoiceWithHeaders() async {
    try {
      // Get URL with authentication headers
      final urlWithHeaders = await _orderService.getInvoiceUrlWithHeaders(
        widget.orderId,
        type: 'print',
      );
      final url = urlWithHeaders['url'];

      if (url != null && url.isNotEmpty) {
        // Extract headers (remove 'url' key)
        final headers = Map<String, String>.from(urlWithHeaders);
        headers.remove('url');

        setState(() {
          _invoiceUrl = url;
          _headers = headers;
          _isLoading = false;
        });

        // Initialize WebView controller with headers
        _initializeWebViewWithHeaders();
      } else {
        setState(() {
          _errorMessage = 'orders.invoice_not_available'.tr();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    if (_invoiceUrl == null) return;

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                }
              },
              onPageFinished: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage =
                        'Failed to load invoice: ${error.description}';
                  });
                }
              },
              onHttpError: (HttpResponseError error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage =
                        'HTTP Error: ${error.response?.statusCode ?? 'Unknown'}';
                  });
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(_invoiceUrl!));
  }

  void _initializeWebViewWithHeaders() {
    if (_invoiceUrl == null || _headers == null) return;

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setUserAgent(
            _headers!['User-Agent'] ??
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0',
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                }
              },
              onPageFinished: (String url) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage =
                        'Authentication failed: ${error.description}';
                  });
                }
              },
              onHttpError: (HttpResponseError error) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage =
                        'Authentication Error: ${error.response?.statusCode ?? 'Unauthorized'}';
                  });
                }
              },
            ),
          );

    // Load request with authentication headers
    final uri = Uri.parse(_invoiceUrl!);
    _controller!.loadRequest(uri, headers: _headers!);
  }

  Future<void> _downloadInvoice() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Get download URL and open in external app/browser
      final downloadUrl = await _orderService.getInvoiceUrl(
        widget.orderId,
        type: 'download',
      );

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        if (await canLaunchUrl(Uri.parse(downloadUrl))) {
          await launchUrl(
            Uri.parse(downloadUrl),
            mode: LaunchMode.externalApplication,
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
          throw Exception('Could not open download URL');
        }
      } else {
        throw Exception('Download URL not available');
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
    if (_invoiceUrl != null) {
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: _invoiceUrl!,
            subject: 'Invoice for Order ${widget.orderCode}',
          ),
        );
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
  }

  Future<void> _openInBrowser() async {
    try {
      final url = await _orderService.getInvoiceUrl(widget.orderId);
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open invoice in browser');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
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
          if (_invoiceUrl != null) ...[
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black),
              onPressed: _shareInvoice,
              tooltip: 'Share Invoice',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser, color: Colors.black),
              onPressed: _openInBrowser,
              tooltip: 'Open in Browser',
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
            onPressed: _loadInvoice,
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
                onPressed: _loadInvoice,
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

    if (_invoiceUrl != null && _controller != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
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
