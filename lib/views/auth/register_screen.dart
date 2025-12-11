import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';
import '../webview/terms_privacy_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.client;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showLawyerFields = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    // Reset error state
    setState(() {
      _showTermsError = false;
    });

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Then check terms and privacy acceptance
    if (!_acceptedTerms || !_acceptedPrivacy) {
      setState(() {
        _showTermsError = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mustAcceptTerms),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Proceed with registration
    final phoneValue = _phoneController.text.trim();

    final success = await ref.read(authControllerProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole.value,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: phoneValue.isEmpty ? null : phoneValue,
      lawyerData: null,
      acceptedTerms: _acceptedTerms,
      acceptedPrivacy: _acceptedPrivacy,
    );

    if (mounted) {
      if (success) {
        // Navigation handled by auth state listener
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(authControllerProvider).errorMessage ?? 'Registration failed',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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

  void _onTermsChanged(bool? value) {
    if (value != null) {
      setState(() {
        _acceptedTerms = value;
        if (value && _acceptedPrivacy) {
          _showTermsError = false;
        }
      });
    }
  }

  void _onPrivacyChanged(bool? value) {
    if (value != null) {
      setState(() {
        _acceptedPrivacy = value;
        if (value && _acceptedTerms) {
          _showTermsError = false;
        }
      });
    }
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
        title: Text(
          l10n.register,
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
                const SizedBox(height: 24),
                Text(
                  l10n.createAccount,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.joinNepalAdvocate,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                // Role Selection
                Text(
                  l10n.iAmA,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.client),
                        selected: _selectedRole == UserRole.client,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRole = UserRole.client;
                              _showLawyerFields = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l10n.lawyer),
                        selected: _selectedRole == UserRole.lawyer,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRole = UserRole.lawyer;
                              _showLawyerFields = true;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                AppTextField(
                  label: l10n.firstName,
                  hint: '${l10n.enter} ${l10n.firstName.toLowerCase()}',
                  controller: _firstNameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${l10n.pleaseEnter} ${l10n.firstName.toLowerCase()}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                AppTextField(
                  label: l10n.lastName,
                  hint: '${l10n.enter} ${l10n.lastName.toLowerCase()}',
                  controller: _lastNameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${l10n.pleaseEnter} ${l10n.lastName.toLowerCase()}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
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
                  label: '${l10n.phone} (${l10n.optional})',
                  hint: '${l10n.enter} ${l10n.phone.toLowerCase()}',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
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
                const SizedBox(height: AppConstants.spacingM),
                AppTextField(
                  label: l10n.confirmPassword,
                  hint: '${l10n.confirm} ${l10n.password.toLowerCase()}',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${l10n.pleaseEnter} ${l10n.confirmPassword.toLowerCase()}';
                    }
                    if (value != _passwordController.text) {
                      return '${l10n.password} ${l10n.doNotMatch}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.spacingL),
                // Terms and Privacy Acceptance
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showTermsError
                          ? AppTheme.errorColor
                          : AppTheme.textSecondary.withOpacity(0.3),
                      width: _showTermsError ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: _onTermsChanged,
                        title: Row(
                          children: [
                            Text(
                              '${l10n.acceptTerms.split('Terms of Service')[0].trim()} ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            GestureDetector(
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
                              child: Text(
                                l10n.termsOfService,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      CheckboxListTile(
                        value: _acceptedPrivacy,
                        onChanged: _onPrivacyChanged,
                        title: Row(
                          children: [
                            Text(
                              '${l10n.acceptPrivacy.split('Privacy Policy')[0].trim()} ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            GestureDetector(
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
                              child: Text(
                                l10n.privacyPolicy,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      if (_showTermsError) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.mustAcceptTerms,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),
                AppButton(
                  text: l10n.register,
                  onPressed: _handleRegister,
                  isLoading: authState.state == AuthState.authenticating,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}