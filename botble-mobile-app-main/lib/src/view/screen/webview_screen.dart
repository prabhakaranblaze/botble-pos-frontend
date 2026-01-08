import 'dart:async';
import 'package:flutter/material.dart';
import 'package:martfury/src/theme/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({super.key, required this.url, required this.title});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  WebViewController? _controller;
  Timer? _initTimer;
  Timer? _loadTimer;
  bool _isDisposed = false;
  int _criticalErrorCount = 0;
  bool _pageLoadedSuccessfully = false;
  
  // Track active WebView instances
  static final Set<WebViewController> _activeControllers = {};
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Delay initialization to prevent buffer issues
    _initTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isDisposed && mounted) {
        _initializeWebView();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isDisposed && _controller != null) {
      if (state == AppLifecycleState.paused) {
        // Pause any media when app goes to background
        _pauseMedia();
      } else if (state == AppLifecycleState.detached) {
        // Free resources when app is being closed
        _freeResources();
      }
    }
  }
  
  void _pauseMedia() {
    _controller?.runJavaScript('''
      var videos = document.getElementsByTagName('video');
      for (var i = 0; i < videos.length; i++) {
        videos[i].pause();
      }
      var audios = document.getElementsByTagName('audio');
      for (var i = 0; i < audios.length; i++) {
        audios[i].pause();
      }
    ''').catchError((e) {
      debugPrint('Error pausing media: $e');
    });
  }
  
  void _freeResources() {
    try {
      _controller?.clearCache();
      _controller?.clearLocalStorage();
    } catch (e) {
      debugPrint('Error freeing resources: $e');
    }
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-App/1.0')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('WebView started loading: $url');
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = null;
                });
              }
            },
            onPageFinished: (String url) {
              debugPrint('WebView finished loading: $url');
              _pageLoadedSuccessfully = true;
              _criticalErrorCount = 0; // Reset error count on successful load
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoading = false;
                });
                // Inject optimizations
                _injectOptimizations();
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.errorCode} - ${error.description}');
              
              // Ignore non-critical errors for secondary resources after page loads
              if (_pageLoadedSuccessfully) {
                // These are typically errors for ads, analytics, or embedded content
                if (error.errorCode == -2 || // ERR_NAME_NOT_RESOLVED
                    error.errorCode == -6 || // ERR_CONNECTION_REFUSED
                    error.errorCode == -7) { // ERR_CONNECTION_TIMED_OUT
                  debugPrint('Ignoring non-critical resource error');
                  return;
                }
              }
              
              // Only treat as critical error if it's the main page or repeated errors
              if (!_pageLoadedSuccessfully || error.isForMainFrame == true) {
                _criticalErrorCount++;
                if (_criticalErrorCount > 5) {
                  if (!_isDisposed && mounted) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage = _getReadableErrorMessage(error);
                    });
                  }
                }
              }
            },
            onHttpError: (HttpResponseError error) {
              debugPrint('HTTP error: ${error.response?.statusCode}');
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Prevent opening external apps
              if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        );
      
      // Register controller
      if (_controller != null) {
        _activeControllers.add(_controller!);
        debugPrint('WebView registered. Active count: ${_activeControllers.length}');
      }
      
      // Configure additional settings for better compatibility
      _controller!.setOnConsoleMessage((JavaScriptConsoleMessage message) {
        debugPrint('JS Console: ${message.message}');
      });
      
      // Load URL with delay to prevent buffer issues
      _loadTimer = Timer(const Duration(milliseconds: 200), () {
        if (!_isDisposed && mounted && _controller != null) {
          _pageLoadedSuccessfully = false;
          _criticalErrorCount = 0;
          _controller!.loadRequest(
            Uri.parse(widget.url),
            headers: {
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
              'Accept-Encoding': 'gzip, deflate',
              'Connection': 'keep-alive',
              'Upgrade-Insecure-Requests': '1',
              'Cache-Control': 'no-cache',
              'DNT': '1',
            },
          );
        }
      });
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize WebView';
        });
      }
    }
  }
  
  void _injectOptimizations() {
    if (_controller != null && !_isDisposed) {
      _controller!.runJavaScript('''
        // Optimize image loading
        var images = document.getElementsByTagName('img');
        for (var i = 0; i < images.length; i++) {
          if (!images[i].loading) {
            images[i].loading = 'lazy';
          }
        }
        
        // Reduce memory usage by limiting image sizes
        var style = document.createElement('style');
        style.innerHTML = 'img { max-width: 100%; height: auto; }';
        document.head.appendChild(style);
        
        // Disable autoplay for videos to save resources
        var videos = document.getElementsByTagName('video');
        for (var i = 0; i < videos.length; i++) {
          videos[i].autoplay = false;
        }
        
        // Handle iframe errors gracefully
        var iframes = document.getElementsByTagName('iframe');
        for (var i = 0; i < iframes.length; i++) {
          iframes[i].onerror = function() {
            console.log('Iframe load error - ignoring');
            return true;
          };
        }
        
        // Suppress network errors for non-critical resources
        window.addEventListener('error', function(e) {
          if (e.target && (e.target.tagName === 'IMG' || e.target.tagName === 'SCRIPT')) {
            e.preventDefault();
            return true;
          }
        }, true);
      ''').catchError((e) {
        debugPrint('Error injecting optimizations: $e');
      });
    }
  }
  
  String _getReadableErrorMessage(WebResourceError error) {
    // Common error codes
    switch (error.errorCode) {
      case -2: // ERR_NAME_NOT_RESOLVED
        return 'Cannot resolve server address. Please check your internet connection.';
      case -6: // ERR_CONNECTION_REFUSED
        return 'Connection refused by server. Please try again later.';
      case -7: // ERR_CONNECTION_TIMED_OUT
        return 'Connection timed out. Please check your network.';
      case -1001:
        return 'Request timed out. Please check your connection and try again.';
      case -1009:
        return 'No internet connection. Please check your network.';
      case -1004:
        return 'Cannot connect to server. Please try again.';
      case -1200:
        return 'SSL connection error. Please try again.';
      case -1003:
        return 'Server not found. Please check the URL.';
      case -1005:
        return 'Network connection lost. Please try again.';
      default:
        if (error.description.isNotEmpty && !error.description.contains('net::')) {
          return error.description;
        }
        return 'Connection error occurred. Please try again.';
    }
  }

  void _refreshWebView() {
    if (!_isDisposed && mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        _pageLoadedSuccessfully = false;
        _criticalErrorCount = 0;
      });

      if (_controller != null) {
        _controller!.reload();
      } else {
        // Reinitialize if controller is null
        _initializeWebView();
      }
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _initTimer?.cancel();
    _loadTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    
    // Unregister and properly dispose of the WebView
    if (_controller != null) {
      _activeControllers.remove(_controller!);
      debugPrint('WebView unregistered. Active count: ${_activeControllers.length}');
      
      // Free resources
      try {
        _controller!.clearCache();
        _controller!.clearLocalStorage();
      } catch (e) {
        debugPrint('Error clearing WebView cache: $e');
      }
      
      _controller = null;
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshWebView,
              tooltip: 'common.refresh'.tr(),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError && _controller != null) 
            WebViewWidget(controller: _controller!),
          if (_hasError) _buildErrorWidget(),
          if (_isLoading && !_hasError)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'common.connection_error'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Reinitialize WebView completely on error retry
                setState(() {
                  _controller = null;
                  _hasError = false;
                  _isLoading = true;
                  _pageLoadedSuccessfully = false;
                  _criticalErrorCount = 0;
                });
                _initializeWebView();
              },
              icon: const Icon(Icons.refresh),
              label: Text('common.try_again'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}