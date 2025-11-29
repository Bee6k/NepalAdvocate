import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/verification_controller.dart';
import '../../services/verification_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../chat/chat_screen.dart';
import '../documents/document_upload_screen.dart';
import '../lawyers/lawyer_profile_edit_screen.dart';
import '../clients/lawyer_clients_screen.dart';
import '../../widgets/appointments/propose_time_dialog.dart';

class LawyerDashboard extends ConsumerStatefulWidget {
  const LawyerDashboard({super.key});

  @override
  ConsumerState<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends ConsumerState<LawyerDashboard> {
  bool _showWelcome = true;
  Timer? _welcomeTimer;

  @override
  void initState() {
    super.initState();
    // Show welcome for 4 seconds
    _welcomeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showWelcome = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final appointmentsAsync = ref.watch(appointmentControllerProvider);
    final currentDate = DateFormat('dd MMM').format(DateTime.now()).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepal Advocate'),
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _showWelcome
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Welcome!',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage your appointments and clients',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isEmpty
                                          ? 'Lawyer'
                                          : '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (user?.email != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        user!.email!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        user.phone!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentDate,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                            ),
                            if (user?.lawyerProfile == null || user!.lawyerProfile!.hourlyRate == 0)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Complete your profile',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LawyerProfileEditScreen(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        VerifiedAvatar(
                          imageUrl: user?.profilePicture,
                          name: user?.fullName,
                          radius: 28,
                          isVerified: user?.lawyerProfile?.isVerified ?? false,
                        ),
                      ],
                    ),
                    if (user?.lawyerProfile != null) ...[
                      const SizedBox(height: 16),
                      // Verification status
                      if (!user!.lawyerProfile!.isVerified)
                        Builder(
                          builder: (context) {
                            final verificationStatusAsync = ref.watch(verificationStatusProvider);
                            
                            return verificationStatusAsync.when(
                              data: (status) {
                                final hasPendingRequest = status['verificationRequest'] != null && 
                                    status['verificationRequest']['status'] == 'PENDING';
                                final wasRejected = status['verificationRequest'] != null && 
                                    status['verificationRequest']['status'] == 'REJECTED';
                                
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: wasRejected 
                                        ? AppTheme.errorColor.withOpacity(0.2)
                                        : AppTheme.warningColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: wasRejected
                                          ? AppTheme.errorColor.withOpacity(0.5)
                                          : AppTheme.warningColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            wasRejected ? Icons.cancel : Icons.pending_actions,
                                            color: wasRejected ? AppTheme.errorColor : AppTheme.warningColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              wasRejected 
                                                  ? 'Verification Request Rejected'
                                                  : hasPendingRequest
                                                      ? 'Verification Request Submitted'
                                                      : 'Profile Verification Required',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    color: wasRejected ? AppTheme.errorColor : AppTheme.warningColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        wasRejected
                                            ? status['verificationRequest']['rejectionReason'] ?? 
                                              'Your verification request was rejected. Please review your profile and submit again.'
                                            : hasPendingRequest
                                                ? 'Your verification request has been submitted and is under review. You will be notified once an admin reviews your profile.'
                                                : 'Complete your profile and submit a verification request. You will be able to edit your hourly rate after verification.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: wasRejected ? AppTheme.errorColor : AppTheme.warningColor,
                                            ),
                                      ),
                                      if (!hasPendingRequest) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              try {
                                                final service = ref.read(verificationServiceProvider);
                                                await service.submitVerificationRequest();
                                                ref.invalidate(verificationStatusProvider);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Verification request submitted successfully!'),
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
                                            icon: const Icon(Icons.verified_user),
                                            label: const Text('Apply for Verification'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                              loading: () => Container(
                                padding: const EdgeInsets.all(12),
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              error: (error, stack) => Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Profile Verification Required',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: AppTheme.warningColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          try {
                                            final service = ref.read(verificationServiceProvider);
                                            await service.submitVerificationRequest();
                                            ref.invalidate(verificationStatusProvider);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Verification request submitted successfully!'),
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
                                        icon: const Icon(Icons.verified_user),
                                        label: const Text('Apply for Verification'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (user.lawyerProfile!.rating > 0) ...[
                            Icon(
                              Icons.star,
                              size: 20,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.lawyerProfile!.rating.toStringAsFixed(1)} (${user.lawyerProfile!.totalReviews} reviews)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 16),
                          ],
                          Text(
                            'Rs. ${user.lawyerProfile!.hourlyRate.toStringAsFixed(0)}/hr',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Complete your profile to start receiving appointments',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.warningColor,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LawyerProfileEditScreen(),
                                  ),
                                );
                              },
                              child: const Text('Complete Now'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LawyerClientsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Clients',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Manage your clients',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                          // Navigate to chat if conversation exists
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment.client?.fullName ?? 'Client',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('MMM dd, yyyy • hh:mm a').format(appointment.proposedDate),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appointment.reason,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: appointment.status.value == 'CONFIRMED'
                                        ? AppTheme.successColor.withOpacity(0.2)
                                        : appointment.status.value == 'PENDING'
                                            ? AppTheme.warningColor.withOpacity(0.2)
                                            : AppTheme.textSecondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    appointment.status.value,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: appointment.status.value == 'CONFIRMED'
                                              ? AppTheme.successColor
                                              : appointment.status.value == 'PENDING'
                                                  ? AppTheme.warningColor
                                                  : AppTheme.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            if (appointment.conversationId != null && appointment.status.value == 'CONFIRMED')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
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
                              ),
                            const SizedBox(height: 8),
                            if (appointment.status.value == 'PENDING') ...[
                              // Accept button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ref.read(appointmentControllerProvider.notifier).acceptAppointment(appointment.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Appointment accepted successfully!'),
                                            backgroundColor: AppTheme.successColor,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to accept appointment: ${e.toString()}'),
                                            backgroundColor: AppTheme.errorColor,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        // Show dialog to confirm rejection
                                        final shouldReject = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Reject Appointment'),
                                            content: const Text('Are you sure you want to reject this appointment request?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: AppTheme.errorColor,
                                                ),
                                                child: const Text('Reject'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (shouldReject == true) {
                                          try {
                                            await ref.read(appointmentControllerProvider.notifier).rejectAppointment(appointment.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Appointment rejected'),
                                                  backgroundColor: AppTheme.errorColor,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to reject appointment: ${e.toString()}'),
                                                  backgroundColor: AppTheme.errorColor,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.errorColor,
                                        side: BorderSide(color: AppTheme.errorColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog<Map<String, dynamic>>(
                                          context: context,
                                          builder: (context) => ProposeTimeDialog(
                                            initialDate: appointment.proposedDate,
                                            initialTime: appointment.proposedTime,
                                          ),
                                        );

                                        if (result != null && mounted) {
                                          try {
                                            await ref.read(appointmentControllerProvider.notifier).proposeTime(
                                                  appointmentId: appointment.id,
                                                  proposedDate: result['date'] as DateTime,
                                                  proposedTime: result['time'] as String,
                                                );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Time proposed successfully! Client will be notified.'),
                                                  backgroundColor: AppTheme.successColor,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to propose time: ${e.toString()}'),
                                                  backgroundColor: AppTheme.errorColor,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.schedule, size: 18),
                                      label: const Text('Propose Time'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (appointment.status.value == 'PROPOSED') ...[
                              // Show message if client hasn't accepted yet
                              if (!appointment.clientConfirmation) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: AppTheme.accentColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Waiting for client to accept the proposed time',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppTheme.accentColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Show confirm button only after client accepts
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await ref.read(appointmentControllerProvider.notifier).confirmAppointment(appointment.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Appointment confirmed'),
                                              backgroundColor: AppTheme.successColor,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to confirm: ${e.toString()}'),
                                              backgroundColor: AppTheme.errorColor,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Confirm Appointment'),
                                  ),
                                ),
                              ],
                            ],
                            if (appointment.conversationId != null && appointment.status.value == 'CONFIRMED') ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.upload_file),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DocumentUploadScreen(
                                            appointmentId: appointment.id,
                                          ),
                                        ),
                                      );
                                    },
                                    tooltip: 'Upload Document',
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) {
                  // Check if it's a timeout or connection error
                  String errorMessage = 'Unable to load appointments';
                  String? detailedMessage;
                  
                  if (error is DioException) {
                    if (error.type == DioExceptionType.connectionTimeout ||
                        error.type == DioExceptionType.receiveTimeout ||
                        error.type == DioExceptionType.sendTimeout) {
                      errorMessage = 'Connection timeout';
                      detailedMessage = 'The server is taking too long to respond. This may happen if the backend is starting up. Please try again in a moment.';
                    } else if (error.type == DioExceptionType.connectionError) {
                      errorMessage = 'Connection error';
                      detailedMessage = 'Unable to connect to the server. Please check your internet connection and try again.';
                    } else {
                      errorMessage = 'Error loading appointments';
                      detailedMessage = error.message ?? error.toString();
                    }
                  } else {
                    detailedMessage = error.toString();
                  }
                  
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (detailedMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            detailedMessage,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(appointmentControllerProvider.notifier).loadAppointments();
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

