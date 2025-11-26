import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingXL),
            _buildSection(
              context,
              '1. Introduction',
              'NepalAdvocate ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              'We collect information that you provide directly to us:\n\n• Account Information: Name, email address, phone number, password\n• Profile Information: For lawyers, we collect professional information including bar license number, specialization, experience, and hourly rates\n• Communication Data: Messages exchanged between clients and lawyers\n• Appointment Data: Appointment details, dates, and related information\n• Document Data: Legal documents uploaded to the platform\n• Usage Data: Information about how you use the app',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process your registration and manage your account\n• Facilitate communication between clients and lawyers\n• Process appointments and bookings\n• Send you notifications and updates\n• Respond to your inquiries and support requests\n• Detect and prevent fraud or abuse\n• Comply with legal obligations',
            ),
            _buildSection(
              context,
              '4. Information Sharing',
              'We do not sell your personal information. We may share your information in the following circumstances:\n\n• With lawyers (for clients) or clients (for lawyers) as necessary to provide services\n• With service providers who assist us in operating our platform\n• When required by law or to protect our rights\n• In connection with a business transfer or merger\n• With your consent',
            ),
            _buildSection(
              context,
              '5. Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.',
            ),
            _buildSection(
              context,
              '6. Your Rights',
              'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your information\n• Object to processing of your information\n• Request restriction of processing\n• Data portability\n• Withdraw consent at any time',
            ),
            _buildSection(
              context,
              '7. Cookies and Tracking',
              'We may use cookies and similar tracking technologies to track activity on our app and store certain information. You can instruct your device to refuse all cookies, but this may limit your ability to use some features.',
            ),
            _buildSection(
              context,
              '8. Third-Party Links',
              'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.',
            ),
            _buildSection(
              context,
              '9. Children\'s Privacy',
              'Our services are not intended for individuals under the age of 18. We do not knowingly collect personal information from children. If you become aware that a child has provided us with personal information, please contact us.',
            ),
            _buildSection(
              context,
              '10. Data Retention',
              'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.',
            ),
            _buildSection(
              context,
              '11. International Data Transfers',
              'Your information may be transferred to and maintained on computers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ.',
            ),
            _buildSection(
              context,
              '12. Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: AppConstants.spacingXL),
            Text(
              'Contact Us',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@nepaladvocate.com\nPhone: +977-XXXXXXXXXX',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

