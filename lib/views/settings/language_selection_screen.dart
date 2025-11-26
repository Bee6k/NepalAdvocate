import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        children: [
          _LanguageTile(
            title: l10n.english,
            locale: const Locale('en'),
            currentLocale: currentLocale,
            onTap: () async {
              await ref.read(localeControllerProvider.notifier).setLanguage(const Locale('en'));
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: AppConstants.spacingS),
          _LanguageTile(
            title: l10n.nepali,
            locale: const Locale('ne'),
            currentLocale: currentLocale,
            onTap: () async {
              await ref.read(localeControllerProvider.notifier).setLanguage(const Locale('ne'));
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final Locale locale;
  final Locale currentLocale;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.locale,
    required this.currentLocale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = locale.languageCode == currentLocale.languageCode;

    return Card(
      color: AppTheme.surfaceColor,
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

