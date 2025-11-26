import 'package:flutter/material.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    switch (pageType) {
      case WebViewPageType.terms:
        return const TermsOfServiceScreen();
      case WebViewPageType.privacy:
        return const PrivacyPolicyScreen();
      case WebViewPageType.about:
        return Scaffold(
          appBar: AppBar(
            title: const Text('About NepalAdvocate'),
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'NepalAdvocate is a platform connecting clients with legal professionals in Nepal.',
              ),
            ),
          ),
        );
    }
  }
}

