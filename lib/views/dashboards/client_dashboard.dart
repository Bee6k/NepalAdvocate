import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../documents/documents_list_screen.dart';
import '../appointments/appointment_booking_screen.dart';
import '../chat/chat_screen.dart';
import '../lawyers/lawyer_list_screen.dart';
import '../templates/templates_list_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../../models/appointment_model.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
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
    final l10n = AppLocalizations.of(context)!;
    final currentDate = DateFormat('dd MMM').format(DateTime.now()).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nepalAdvocate),
        actions: [
            IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LawyerListScreen(),
                ),
              );
            },
            tooltip: l10n.bookAppointment,
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
                                      l10n.howCanWeHelp,
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
                                          ? l10n.user
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
                        Text(
                          currentDate,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
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
                          isVerified: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LawyerListScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.search,
                            size: 32,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Find Lawyer',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: AppCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DocumentsListScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder,
                            size: 32,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Documents',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              AppCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TemplatesListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 32,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legal Templates',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse legal document templates',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              // Appointments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Appointments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppointmentsListScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              appointmentsAsync.when(
                data: (appointments) {
                  // Filter out completed and cancelled appointments (they go to history)
                  // and sort by nearest date
                  final unfinishedAppointments = appointments
                      .where((apt) => apt.status != AppointmentStatus.completed && 
                                      apt.status != AppointmentStatus.cancelled)
                      .toList()
                    ..sort((a, b) {
                      final dateA = a.confirmedDate ?? a.proposedDate;
                      final dateB = b.confirmedDate ?? b.proposedDate;
                      return dateA.compareTo(dateB);
                    });

                  if (unfinishedAppointments.isEmpty) {
                    return AppCard(
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No active appointments',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check history for completed and cancelled consultations',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: unfinishedAppointments.take(3).map((appointment) {
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
                            Text(
                              appointment.lawyer?.fullName ?? 'Lawyer',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${appointment.status.value}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (appointment.conversationId != null)
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

