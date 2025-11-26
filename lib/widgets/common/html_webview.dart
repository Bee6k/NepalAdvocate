import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView widget for displaying HTML content directly (not from URL)
class HtmlWebView extends StatefulWidget {
  final String htmlContent;
  final String? title;
  final bool enableJavaScript;

  const HtmlWebView({
    super.key,
    required this.htmlContent,
    this.title,
    this.enableJavaScript = true,
  });

  @override
  State<HtmlWebView> createState() => _HtmlWebViewState();
}

class _HtmlWebViewState extends State<HtmlWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

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
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(
        _wrapHtmlContent(widget.htmlContent),
        baseUrl: 'https://nepaladvocate.app',
      );
  }

  String _wrapHtmlContent(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      background-color: #0E0E11;
      color: #F2F2F2;
      padding: 16px;
      line-height: 1.6;
      margin: 0;
    }
    h1, h2, h3, h4, h5, h6 {
      color: #22E3E8;
      margin-top: 24px;
      margin-bottom: 12px;
    }
    p {
      margin-bottom: 12px;
    }
    a {
      color: #22E3E8;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
    code {
      background-color: #1A1A1F;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: 'Courier New', monospace;
    }
    pre {
      background-color: #1A1A1F;
      padding: 12px;
      border-radius: 8px;
      overflow-x: auto;
    }
    img {
      max-width: 100%;
      height: auto;
      border-radius: 8px;
    }
  </style>
</head>
<body>
  $content
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}

