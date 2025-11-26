import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/appointment_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../chat/chat_screen.dart';
import '../../services/chat_service.dart';

class AppointmentsListScreen extends ConsumerWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentControllerProvider);
    final currentUser = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(appointmentControllerProvider.notifier).loadAppointments();
        },
        child: appointmentsAsync.when(
          data: (appointments) {
            // Filter out completed appointments and sort by nearest date
            final unfinishedAppointments = appointments
                .where((apt) => apt.status != AppointmentStatus.completed)
                .toList()
              ..sort((a, b) {
                // Sort by confirmed date if available, otherwise proposed date
                final dateA = a.confirmedDate ?? a.proposedDate;
                final dateB = b.confirmedDate ?? b.proposedDate;
                return dateA.compareTo(dateB);
              });

            if (unfinishedAppointments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active appointments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All your appointments are completed. Check history for completed consultations.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: unfinishedAppointments.length,
              itemBuilder: (context, index) {
                final appointment = unfinishedAppointments[index];
                final dateFormat = DateFormat('MMM dd, yyyy');
                final timeFormat = DateFormat('hh:mm a');
                final otherUser = currentUser?.role == 'LAWYER'
                    ? appointment.client
                    : appointment.lawyer;

                return AppCard(
                  onTap: () async {
                    if (appointment.conversationId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: appointment.conversationId!,
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          VerifiedAvatar(
                            imageUrl: otherUser?.profilePicture,
                            name: otherUser?.fullName,
                            radius: 24,
                            isVerified: otherUser?.lawyerProfile?.isVerified ?? false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        otherUser?.fullName ?? 'Unknown',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    if (otherUser?.lawyerProfile?.isVerified == true)
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: AppTheme.successColor,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  otherUser?.email ?? '',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(appointment.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              appointment.status.value,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getStatusColor(appointment.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appointment.reason,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.confirmedDate != null
                                ? dateFormat.format(appointment.confirmedDate!)
                                : dateFormat.format(appointment.proposedDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.confirmedTime ?? appointment.proposedTime,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      if (appointment.conversationId != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.chat,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to chat',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(appointmentControllerProvider.notifier).loadAppointments();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppTheme.warningColor;
      case AppointmentStatus.proposed:
        return AppTheme.accentColor;
      case AppointmentStatus.confirmed:
        return AppTheme.successColor;
      case AppointmentStatus.cancelled:
        return AppTheme.errorColor;
      case AppointmentStatus.completed:
        return AppTheme.successColor;
    }
  }
}

