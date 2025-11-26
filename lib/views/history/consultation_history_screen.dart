import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import 'consultation_detail_screen.dart';

class ConsultationHistoryScreen extends ConsumerWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(consultationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation History'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(consultationHistoryProvider);
        },
        child: historyAsync.when(
          data: (appointments) {
            if (appointments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No consultation history',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed and cancelled consultations will appear here',
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
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final dateFormat = DateFormat('MMM dd, yyyy');
                final timeFormat = DateFormat('hh:mm a');
                final otherUser = ref.read(authControllerProvider).user?.role == 'LAWYER'
                    ? appointment.client
                    : appointment.lawyer;

                return AppCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsultationDetailScreen(
                          appointment: appointment,
                          otherUser: otherUser,
                        ),
                      ),
                    );
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
                            isVerified: false,
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
                                if (otherUser != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ref.read(authControllerProvider).user?.role == 'LAWYER'
                                        ? 'Client'
                                        : 'Lawyer',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
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
                              appointment.status == AppointmentStatus.cancelled 
                                  ? 'Cancelled' 
                                  : 'Completed',
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
                      const SizedBox(height: 8),
                      Text(
                        appointment.status == AppointmentStatus.cancelled
                            ? 'Cancelled on ${dateFormat.format(appointment.updatedAt)}'
                            : 'Completed on ${dateFormat.format(appointment.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
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
                  'Error loading history',
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
                    ref.invalidate(consultationHistoryProvider);
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
      case AppointmentStatus.completed:
        return AppTheme.successColor;
      case AppointmentStatus.cancelled:
        return AppTheme.errorColor;
      default:
        return AppTheme.successColor;
    }
  }
}

