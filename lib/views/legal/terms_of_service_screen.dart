import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using NepalAdvocate, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, you should not use this service.',
            ),
            _buildSection(
              context,
              '2. Description of Service',
              'NepalAdvocate is a platform that connects clients with legal professionals (lawyers) in Nepal. We provide services including but not limited to:\n\n• Lawyer search and discovery\n• Appointment booking\n• Legal document templates\n• Chat communication between clients and lawyers\n• Document sharing and management',
            ),
            _buildSection(
              context,
              '3. User Accounts',
              'To use certain features of NepalAdvocate, you must register for an account. You agree to:\n\n• Provide accurate, current, and complete information during registration\n• Maintain and update your information to keep it accurate\n• Maintain the security of your password\n• Accept responsibility for all activities under your account\n• Notify us immediately of any unauthorized use of your account',
            ),
            _buildSection(
              context,
              '4. User Responsibilities',
              'You agree to use NepalAdvocate only for lawful purposes and in accordance with these Terms. You agree not to:\n\n• Violate any applicable laws or regulations\n• Infringe upon the rights of others\n• Transmit any harmful, offensive, or illegal content\n• Impersonate any person or entity\n• Interfere with or disrupt the service\n• Attempt to gain unauthorized access to any part of the service',
            ),
            _buildSection(
              context,
              '5. Lawyer Responsibilities',
              'Lawyers using NepalAdvocate agree to:\n\n• Provide accurate professional information\n• Maintain valid bar license and credentials\n• Respond to client inquiries in a timely manner\n• Maintain confidentiality of client information\n• Provide professional legal services in accordance with applicable laws\n• Not use the platform for any illegal or unethical purposes',
            ),
            _buildSection(
              context,
              '6. No Legal Advice',
              'NepalAdvocate is a platform for connecting clients with lawyers. We do not provide legal advice, and nothing on this platform constitutes legal advice. Any information provided is for general informational purposes only. You should consult with a qualified lawyer for advice specific to your situation.',
            ),
            _buildSection(
              context,
              '7. Fees and Payments',
              '• Clients may be charged consultation fees by lawyers as agreed between parties\n• NepalAdvocate may charge platform fees for certain services\n• All fees are clearly disclosed before services are rendered\n• Refund policies are determined by individual lawyers and service providers',
            ),
            _buildSection(
              context,
              '8. Intellectual Property',
              'All content on NepalAdvocate, including text, graphics, logos, and software, is the property of NepalAdvocate or its content suppliers and is protected by copyright and other intellectual property laws.',
            ),
            _buildSection(
              context,
              '9. Limitation of Liability',
              'NepalAdvocate shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service. We are not responsible for the quality of legal services provided by lawyers on our platform.',
            ),
            _buildSection(
              context,
              '10. Termination',
              'We reserve the right to terminate or suspend your account and access to the service immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
            ),
            _buildSection(
              context,
              '11. Changes to Terms',
              'We reserve the right to modify these Terms at any time. We will notify users of any material changes. Your continued use of the service after such modifications constitutes acceptance of the updated Terms.',
            ),
            _buildSection(
              context,
              '12. Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of Nepal. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts of Nepal.',
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
              'If you have any questions about these Terms of Service, please contact us at:\n\nEmail: support@nepaladvocate.com\nPhone: +977-XXXXXXXXXX',
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

