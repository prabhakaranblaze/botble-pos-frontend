import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:martfury/src/theme/app_colors.dart';

class WebViewDebugScreen extends StatefulWidget {
  final String url;
  final String title;
  final Map<String, String>? headers;

  const WebViewDebugScreen({
    super.key,
    required this.url,
    required this.title,
    this.headers,
  });

  @override
  State<WebViewDebugScreen> createState() => _WebViewDebugScreenState();
}

class _WebViewDebugScreenState extends State<WebViewDebugScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final List<String> _debugLogs = [];
  String? _currentUrl;
  int _loadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugLogs.add('[$timestamp] $message');
    });
  }

  void _initializeWebView() {
    _loadAttempts++;
    _addDebugLog('Initializing WebView (attempt $_loadAttempts)');
    _addDebugLog('Target URL: ${widget.url}');
    _addDebugLog('Headers: ${widget.headers?.keys.join(', ') ?? 'none'}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 MartFury-Debug/1.0',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _addDebugLog('Page started loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
              _errorMessage = null;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            _addDebugLog('Page finished loading: $url');
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            
            // Inject JavaScript to get page info
            _controller?.runJavaScript('''
              console.log('Page title: ' + document.title);
              console.log('Page URL: ' + window.location.href);
              console.log('Document ready state: ' + document.readyState);
              console.log('Body content length: ' + document.body.innerHTML.length);
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            _addDebugLog('Resource error: ${error.description}');
            _addDebugLog('Error type: ${error.errorType}');
            _addDebugLog('Error code: ${error.errorCode}');
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
          onHttpError: (HttpResponseError error) {
            _addDebugLog('HTTP error: ${error.response?.statusCode}');
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'HTTP Error: ${error.response?.statusCode}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            _addDebugLog('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'DebugChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _addDebugLog('JS Message: ${message.message}');
        },
      )
      ..loadRequest(
        Uri.parse(widget.url),
        headers: widget.headers ?? {},
      );

    setState(() {});
  }

  void _reload() {
    _addDebugLog('Manual reload requested');
    if (_controller != null) {
      _controller!.reload();
    } else {
      _initializeWebView();
    }
  }

  void _clearCacheAndReload() {
    _addDebugLog('Clearing cache and reloading');
    if (_controller != null) {
      _controller!.clearCache();
      _controller!.clearLocalStorage();

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _controller != null) {
          _addDebugLog('Cache cleared, reloading page');
          _controller!.reload();
        }
      });
    } else {
      _addDebugLog('Controller is null, reinitializing');
      _initializeWebView();
    }
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearCacheAndReload,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _hasError ? Colors.red[100] : Colors.green[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_hasError ? 'ERROR' : _isLoading ? 'LOADING' : 'LOADED'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hasError ? Colors.red[800] : Colors.green[800],
                  ),
                ),
                if (_currentUrl != null)
                  Text(
                    'Current URL: $_currentUrl',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (_errorMessage != null)
                  Text(
                    'Error: $_errorMessage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[800],
                    ),
                  ),
              ],
            ),
          ),
          
          // WebView
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                if (_controller != null && !_hasError)
                  WebViewWidget(controller: _controller!)
                else if (_hasError)
                  Center(
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
                          'WebView Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _reload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                
                if (_isLoading)
                  Container(
                    color: Colors.white.withValues(alpha: 0.8),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          
          // Debug logs
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[300],
                    child: Text(
                      'Debug Logs (${_debugLogs.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            _debugLogs[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
