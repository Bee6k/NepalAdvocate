import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AppWebView extends StatefulWidget {
  final String url;
  final String? title;
  final Map<String, String>? headers;
  final bool enableJavaScript;
  final VoidCallback? onPageFinished;
  final Function(String)? onUrlChanged;

  const AppWebView({
    super.key,
    required this.url,
    this.title,
    this.headers,
    this.enableJavaScript = true,
    this.onPageFinished,
    this.onUrlChanged,
  });

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String? _errorMessage;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.enableJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            widget.onUrlChanged?.call(url);
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _updateNavigationState();
            widget.onPageFinished?.call();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.url),
        headers: widget.headers ?? {},
      );
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Web View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Bar
          if (_canGoBack || _canGoForward)
            Container(
              color: AppTheme.surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _canGoBack
                        ? () async {
                            await _controller.goBack();
                            _updateNavigationState();
                          }
                        : null,
                    color: _canGoBack ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _canGoForward
                        ? () async {
                            await _controller.goForward();
                            _updateNavigationState();
                          }
                        : null,
                    color: _canGoForward ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _loadingProgress,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
          // WebView Content
          Expanded(
            child: _errorMessage != null
                ? _buildErrorWidget()
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Failed to load page',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                _controller.reload();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

