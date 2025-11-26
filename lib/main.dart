import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/api_client.dart';
import 'core/utils/storage_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/locale_controller.dart';
import 'views/auth/login_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/dashboards/dashboard_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API client
  ApiClient().initialize();
  
  runApp(
    const ProviderScope(
      child: NepalAdvocateApp(),
    ),
  );
}

class NepalAdvocateApp extends ConsumerWidget {
  const NepalAdvocateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      key: ValueKey(locale.languageCode), // Force rebuild when locale changes
      title: 'NepalAdvocate',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isCheckingOnboarding = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final isCompleted = await StorageService().isOnboardingCompleted();
      if (mounted) {
        setState(() {
          _showOnboarding = !isCompleted;
          _isCheckingOnboarding = false;
        });
      }
    } catch (e) {
      print('Error checking onboarding: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = false;
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    final authState = ref.watch(authControllerProvider);

    // Debug: Print auth state changes
    print('AuthWrapper build - State: ${authState.state}, User: ${authState.user?.email}');

    // Handle authenticated state - ensure user exists
    if (authState.state == AuthState.authenticated) {
      if (authState.user != null) {
        print('Navigating to dashboard for role: ${authState.user!.role}');
        return DashboardWrapper(userRole: authState.user!.role);
      } else {
        // User is null but state is authenticated - this shouldn't happen, but handle it
        print('WARNING: Authenticated state but user is null - checking auth status');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(authControllerProvider.notifier).refreshUser();
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
    }

    // Handle other states
    return switch (authState.state) {
      AuthState.unauthenticated => const LoginScreen(),
      AuthState.authenticating => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthState.error => const LoginScreen(),
      AuthState.authenticated => const LoginScreen(), // Fallback (shouldn't reach here)
    };
  }
}

