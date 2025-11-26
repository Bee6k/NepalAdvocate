import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/app_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../templates/templates_list_screen.dart';
import '../admin/verify_lawyers_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.firstName ?? 'Admin'}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage the platform',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            // Admin Actions
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingM),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              children: [
                AppCard(
                  onTap: () {
                    // Navigate to manage users
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage Users',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                AppCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TemplatesListScreen(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 32,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Templates',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                AppCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VerifyLawyersScreen(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 32,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verify Lawyers',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                AppCard(
                  onTap: () {
                    // Navigate to statistics
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 32,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Statistics',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

