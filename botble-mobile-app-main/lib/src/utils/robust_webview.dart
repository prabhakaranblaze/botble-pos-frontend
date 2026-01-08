import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:martfury/src/utils/webview_timeout_handler.dart';

class RobustWebView extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final Function(String)? onPageStarted;
  final Function(String)? onPageFinished;
  final Function(WebResourceError)? onWebResourceError;
  final Function(HttpResponseError)? onHttpError;
  final Function(NavigationRequest)? onNavigationRequest;

  const RobustWebView({
    super.key,
    required this.url,
    this.headers,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.onHttpError,
    this.onNavigationRequest,
  });

  @override
  State<RobustWebView> createState() => _RobustWebViewState();
}

class _RobustWebViewState extends State<RobustWebView> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _urlTested = false;
  Timer? _timeoutTimer;
  int _errorCount = 0;
  bool _isDisposed = false;
  bool _pageLoadedSuccessfully = false;
  int _criticalErrorCount = 0;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Add delay to prevent buffer issues on initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed) {
        _initializeWebView();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    
    _controller = null;
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Pause any media when app goes to background
      _controller?.runJavaScript('if(window.pauseAllMedia) window.pauseAllMedia();');
    }
  }

  Future<void> _testUrlBeforeLoading() async {
    await WebViewTimeoutHandler.testUrlAccessibility(
      widget.url,
      headers: widget.headers,
      timeout: const Duration(seconds: 10),
    );

    setState(() {
      _urlTested = true;
    });
    _loadWebView();
  }

  void _initializeWebView() {
    // Test URL accessibility first
    _testUrlBeforeLoading();
  }

  void _loadWebView() {
    const userAgent = 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0';

    _controller = WebViewTimeoutHandler.createTimeoutResistantController(
      userAgent: userAgent,
      onPageStarted: (String url) {
        _startTimeoutTimer();

        if (mounted) {
          setState(() {
            _isLoading = true;
            _hasError = false;
            _errorMessage = null;
          });
        }

        widget.onPageStarted?.call(url);
      },
      onPageFinished: (String url) {
        _cancelTimeoutTimer();

        // Reset error count on successful load
        _errorCount = 0;
        _criticalErrorCount = 0;
        _pageLoadedSuccessfully = true;

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        
        // Inject error suppression for non-critical resources
        _injectErrorHandling();

        widget.onPageFinished?.call(url);
      },
      onWebResourceError: (WebResourceError error) {
        developer.log('WebView error: ${error.errorCode} - ${error.description}', name: 'RobustWebView');
        
        // Ignore non-critical errors after page loads successfully
        if (_pageLoadedSuccessfully) {
          // DNS, connection refused, timeout errors for secondary resources
          if (error.errorCode == -2 || // ERR_NAME_NOT_RESOLVED
              error.errorCode == -6 || // ERR_CONNECTION_REFUSED  
              error.errorCode == -7 || // ERR_CONNECTION_TIMED_OUT
              error.errorCode == -1001) { // iOS timeout
            developer.log('Ignoring non-critical resource error', name: 'RobustWebView');
            return;
          }
        }
        
        _cancelTimeoutTimer();
        _errorCount++;
        
        // Only show error if it's critical or repeated
        if (!_pageLoadedSuccessfully || error.isForMainFrame == true) {
          _criticalErrorCount++;
          
          // Handle timeout errors with recovery
          if (error.errorCode == -1001 && _errorCount <= 2) {
            _handleTimeoutRecovery();
            return;
          }
          
          if (_criticalErrorCount > 3) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = _getReadableErrorMessage(error);
              });
            }
            widget.onWebResourceError?.call(error);
          }
        }
      },
      onHttpError: (HttpResponseError error) {
        _cancelTimeoutTimer();

        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
          });
        }

        widget.onHttpError?.call(error);
      },
      onNavigationRequest: (NavigationRequest request) {
        return widget.onNavigationRequest?.call(request) ??
               NavigationDecision.navigate;
      },
    );
    
    // Load URL with enhanced timeout handling
    WebViewTimeoutHandler.loadUrlWithTimeoutHandling(
      _controller!,
      widget.url,
      headers: widget.headers,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Page loading timed out. Please check your connection and try again.';
        });
      }
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
  }

  void _handleTimeoutRecovery() {
    if (_controller != null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Perform aggressive timeout recovery
      WebViewTimeoutHandler.performTimeoutRecovery(
        _controller!,
        widget.url,
        headers: widget.headers,
      );
    }
  }

  void _injectErrorHandling() {
    if (_controller != null && !_isDisposed) {
      _controller!.runJavaScript('''
        // Suppress errors for non-critical resources
        window.addEventListener('error', function(e) {
          if (e.target && (e.target.tagName === 'IMG' || 
                          e.target.tagName === 'SCRIPT' || 
                          e.target.tagName === 'IFRAME')) {
            e.preventDefault();
            return true;
          }
        }, true);
        
        // Handle iframe errors
        var iframes = document.getElementsByTagName('iframe');
        for (var i = 0; i < iframes.length; i++) {
          iframes[i].onerror = function() { return true; };
        }
      ''').catchError((e) {
        developer.log('Error injecting error handling: $e', name: 'RobustWebView');
      });
    }
  }
  
  String _getReadableErrorMessage(WebResourceError error) {
    // Handle DNS and network error codes
    if (error.errorCode == -2) {
      return 'Cannot resolve server address. Please check your internet connection.';
    }
    
    if (error.errorCode == -6) {
      return 'Connection refused by server. Please try again later.';
    }
    
    if (error.errorCode == -7) {
      return 'Connection timed out. Please check your network.';
    }
    
    // Handle WebKit-specific error codes
    if (error.errorCode == -1001) {
      return 'Request timed out. The server is taking too long to respond. Please try again.';
    }

    if (error.errorCode == -1009) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error.errorCode == -1004) {
      return 'Cannot connect to server. Please check your internet connection.';
    }

    if (error.errorCode == -1200) {
      return 'SSL connection error. Please try again.';
    }

    // Handle error types when available
    if (error.errorType != null) {
      switch (error.errorType) {
        case WebResourceErrorType.hostLookup:
          return 'Cannot find the server. Please check your internet connection.';
        case WebResourceErrorType.timeout:
          return 'The request timed out. Please try again.';
        case WebResourceErrorType.connect:
          return 'Cannot connect to the server. Please check your internet connection.';
        case WebResourceErrorType.authentication:
          return 'Authentication failed. Please try logging in again.';
        case WebResourceErrorType.unsupportedScheme:
          return 'Unsupported URL format.';
        default:
          break;
      }
    }

    // Fallback to description or generic message
    if (error.description.isNotEmpty && !error.description.contains('net::')) {
      return error.description;
    }

    return 'Connection error occurred. Please try again.';
  }

  void refresh() {
    // If we've had multiple errors, completely reinitialize the WebView
    if (_errorCount >= 2) {
      _completeReset();
      return;
    }

    if (_controller != null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        _pageLoadedSuccessfully = false;
        _criticalErrorCount = 0;
      });

      // Use aggressive timeout recovery
      WebViewTimeoutHandler.performTimeoutRecovery(
        _controller!,
        widget.url,
        headers: widget.headers,
      );
    } else {
      // Reinitialize completely if controller is null
      _initializeWebView();
    }
  }

  void _completeReset() {
    // Cancel any existing timers
    _cancelTimeoutTimer();

    // Reset all state
    setState(() {
      _controller = null;
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _urlTested = false;
      _errorCount = 0;
      _pageLoadedSuccessfully = false;
      _criticalErrorCount = 0;
    });

    // Reinitialize from scratch
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_urlTested || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to server...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
