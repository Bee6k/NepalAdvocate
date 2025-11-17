import 'package:flutter/material.dart';
import '../../widgets/common/app_webview.dart';

enum WebViewPageType {
  terms,
  privacy,
  about,
}

class TermsPrivacyScreen extends StatelessWidget {
  final WebViewPageType pageType;

  const TermsPrivacyScreen({
    super.key,
    required this.pageType,
  });

  String get _url {
    switch (pageType) {
      case WebViewPageType.terms:
        return 'https://nepaladvocate.app/terms'; // Replace with actual URL
      case WebViewPageType.privacy:
        return 'https://nepaladvocate.app/privacy'; // Replace with actual URL
      case WebViewPageType.about:
        return 'https://nepaladvocate.app/about'; // Replace with actual URL
    }
  }

  String get _title {
    switch (pageType) {
      case WebViewPageType.terms:
        return 'Terms of Service';
      case WebViewPageType.privacy:
        return 'Privacy Policy';
      case WebViewPageType.about:
        return 'About NepalAdvocate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWebView(
      url: _url,
      title: _title,
      enableJavaScript: true,
    );
  }
}

