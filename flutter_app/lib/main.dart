import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/api_client.dart';
import 'controllers/auth_controller.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboards/client_dashboard.dart';
import 'views/dashboards/lawyer_dashboard.dart';
import 'views/dashboards/admin_dashboard.dart';

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

class NepalAdvocateApp extends StatelessWidget {
  const NepalAdvocateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NepalAdvocate',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return switch (authState.state) {
      AuthState.unauthenticated => const LoginScreen(),
      AuthState.authenticating => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthState.authenticated => _getDashboardForRole(authState.user!.role),
      AuthState.error => const LoginScreen(),
    };
  }

  Widget _getDashboardForRole(String role) {
    return switch (role) {
      'CLIENT' => const ClientDashboard(),
      'LAWYER' => const LawyerDashboard(),
      'ADMIN' => const AdminDashboard(),
      _ => const LoginScreen(),
    };
  }
}

