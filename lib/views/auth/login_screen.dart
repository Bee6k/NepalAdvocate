import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        if (success) {
          // Wait a bit for state to propagate and UI to rebuild
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Verify we're authenticated - if not, show error
          final authState = ref.read(authControllerProvider);
          if (authState.state != AuthState.authenticated) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authState.errorMessage ?? l10n.loginFailed,
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          // Navigation is handled by AuthWrapper watching auth state
        } else {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ref.read(authControllerProvider).errorMessage ?? l10n.loginFailed,
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _toggleLanguage() {
    final currentLocale = ref.read(localeControllerProvider);
    final newLocale = currentLocale.languageCode == 'en' 
        ? const Locale('ne') 
        : const Locale('en');
    ref.read(localeControllerProvider.notifier).setLanguage(newLocale);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.language,
              color: AppTheme.primaryColor,
            ),
            tooltip: l10n.language,
            onPressed: _toggleLanguage,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcome,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                AppTextField(
                  label: l10n.email,
                  hint: l10n.enterYourEmail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${l10n.pleaseEnter} ${l10n.email.toLowerCase()}';
                    }
                    if (!value.contains('@')) {
                      return '${l10n.pleaseEnter} ${l10n.validEmail}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                AppTextField(
                  label: l10n.password,
                  hint: l10n.enterYourPassword,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${l10n.pleaseEnter} ${l10n.password.toLowerCase()}';
                    }
                    if (value.length < 6) {
                      return l10n.passwordMustBe;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingXL),
                AppButton(
                  text: l10n.login,
                  onPressed: _handleLogin,
                  isLoading: authState.state == AuthState.authenticating,
                ),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l10n.dontHaveAccount} ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(l10n.register),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

