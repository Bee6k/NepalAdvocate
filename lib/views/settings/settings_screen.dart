import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../services/profile_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../../widgets/common/profile_picture_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../webview/terms_privacy_screen.dart';
import '../lawyers/lawyer_profile_edit_screen.dart';
import '../profile/client_profile_edit_screen.dart';
import '../notifications/notifications_screen.dart';
import '../history/consultation_history_screen.dart';
import 'language_selection_screen.dart';
import '../../controllers/locale_controller.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        children: [
          // Profile Section
          AppCard(
            child: Column(
              children: [
                ProfilePicturePicker(
                  currentImageUrl: user?.profilePicture,
                  name: user?.fullName,
                  isVerified: user?.lawyerProfile?.isVerified ?? false,
                  radius: 40,
                  onImageSelected: (File imageFile) async {
                    try {
                      final profileService = ProfileService();
                      final updatedUser = await profileService.uploadProfilePicture(imageFile);
                      await ref.read(authControllerProvider.notifier).refreshUser();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile picture updated successfully'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                  onRemoveImage: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                      ? () async {
                          try {
                            final profileService = ProfileService();
                            await profileService.deleteProfilePicture();
                            await ref.read(authControllerProvider.notifier).refreshUser();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile picture removed successfully'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  user?.fullName ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          // Settings Options
          _SettingsSection(
            title: l10n.account,
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: user?.role == 'LAWYER' ? l10n.editLawyerProfile : l10n.editProfile,
                onTap: () {
                  if (user?.role == 'LAWYER') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LawyerProfileEditScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientProfileEditScreen(),
                      ),
                    );
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: l10n.changePassword,
                onTap: () {
                  // Navigate to change password
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          _SettingsSection(
            title: l10n.preferences,
            children: [
              _SettingsTile(
                icon: Icons.history,
                title: 'Consultation History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConsultationHistoryScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.language,
                title: l10n.language,
                trailing: Text(
                  ref.watch(localeControllerProvider).languageCode == 'ne' 
                      ? l10n.nepali 
                      : l10n.english,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          _SettingsSection(
            title: l10n.about,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: l10n.appVersion,
                trailing: const Text('1.0.0'),
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsPrivacyScreen(
                        pageType: WebViewPageType.privacy,
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsPrivacyScreen(
                        pageType: WebViewPageType.terms,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXL),
          // Logout Button
          ElevatedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppConstants.spacingM),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

