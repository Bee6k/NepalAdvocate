import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/app_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class LawyerDashboard extends ConsumerWidget {
  const LawyerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final appointmentsAsync = ref.watch(appointmentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawyer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(appointmentControllerProvider.notifier).loadAppointments();
        },
        child: SingleChildScrollView(
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
                      'Welcome, ${user?.firstName ?? 'Lawyer'}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your appointments and clients',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Appointments Section
              Text(
                'Pending Appointments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.spacingM),
              appointmentsAsync.when(
                data: (appointments) {
                  final pending = appointments
                      .where((a) => a.status.value == 'PENDING' || a.status.value == 'PROPOSED')
                      .toList();

                  if (pending.isEmpty) {
                    return AppCard(
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending appointments',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: pending.take(5).map((appointment) {
                      return AppCard(
                        onTap: () {
                          // Navigate to appointment details
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.client?.fullName ?? 'Client',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${appointment.status.value}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (appointment.status.value == 'PROPOSED')
                                  TextButton(
                                    onPressed: () {
                                      // Confirm appointment
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                TextButton(
                                  onPressed: () {
                                    // Propose new time
                                  },
                                  child: const Text('Propose Time'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => AppCard(
                  child: Text(
                    'Error loading appointments: ${error.toString()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

