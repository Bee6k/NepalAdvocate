import 'package:flutter/material.dart';
import '../../widgets/common/html_webview.dart';
import '../../models/legal_template_model.dart';

class TemplateViewerScreen extends StatelessWidget {
  final LegalTemplateModel template;

  const TemplateViewerScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return HtmlWebView(
      title: template.title,
      htmlContent: template.content,
      enableJavaScript: false,
    );
  }
}

