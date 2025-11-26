import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../services/client_service.dart';
import '../../services/chat_service.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../chat/chat_screen.dart';
import 'shared_files_screen.dart';

class LawyerClientsScreen extends ConsumerWidget {
  const LawyerClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientsProvider);
        },
        child: clientsAsync.when(
          data: (clients) {
            if (clients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No clients yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your clients will appear here once they book appointments',
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
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final clientData = clients[index];
                final client = clientData.client;
                final dateFormat = DateFormat('MMM dd, yyyy');

                return AppCard(
                  onTap: () {
                    _showClientDetails(context, ref, clientData);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          VerifiedAvatar(
                            imageUrl: client.profilePicture,
                            name: client.fullName,
                            radius: 24,
                            isVerified: false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.fullName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (client.email != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    client.email!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat),
                            color: AppTheme.primaryColor,
                            onPressed: () async {
                              await _navigateToChat(context, ref, client.id);
                            },
                            tooltip: 'Chat',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatChip(
                            context,
                            Icons.event,
                            '${clientData.totalAppointments}',
                            'Total',
                          ),
                          const SizedBox(width: 8),
                          if (clientData.pendingAppointments > 0)
                            _buildStatChip(
                              context,
                              Icons.pending,
                              '${clientData.pendingAppointments}',
                              'Pending',
                              color: AppTheme.warningColor,
                            ),
                          const SizedBox(width: 8),
                          if (clientData.confirmedAppointments > 0)
                            _buildStatChip(
                              context,
                              Icons.check_circle,
                              '${clientData.confirmedAppointments}',
                              'Confirmed',
                              color: AppTheme.successColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last appointment: ${dateFormat.format(clientData.lastAppointmentDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
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
                  'Error loading clients',
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
                    ref.invalidate(clientsProvider);
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

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(BuildContext context, WidgetRef ref, ClientWithStats clientData) {
    final client = clientData.client;
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    VerifiedAvatar(
                      imageUrl: client.profilePicture,
                      name: client.fullName,
                      radius: 32,
                      isVerified: false,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.fullName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (client.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              client.email!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (client.phone != null) ...[
                  _buildDetailRow(context, Icons.phone, 'Phone', client.phone!),
                  const SizedBox(height: 16),
                ],
                _buildDetailRow(
                  context,
                  Icons.event,
                  'Total Appointments',
                  '${clientData.totalAppointments}',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.pending,
                  'Pending',
                  '${clientData.pendingAppointments}',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.check_circle,
                  'Confirmed',
                  '${clientData.confirmedAppointments}',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.done_all,
                  'Completed',
                  '${clientData.completedAppointments}',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.access_time,
                  'Last Appointment',
                  dateFormat.format(clientData.lastAppointmentDate),
                ),
                const SizedBox(height: 32),
                FutureBuilder<List<AppointmentModel>>(
                  future: AppointmentService().getMyAppointments(status: 'CONFIRMED'),
                  builder: (context, snapshot) {
                    AppointmentModel? activeAppointment;
                    if (snapshot.hasData) {
                      try {
                        activeAppointment = snapshot.data!.firstWhere(
                          (apt) => apt.clientId == client.id,
                        );
                      } catch (e) {
                        // No active appointment found
                        activeAppointment = null;
                      }
                    }
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _navigateToChat(context, ref, client.id);
                                },
                                icon: const Icon(Icons.chat),
                                label: const Text('Chat'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SharedFilesScreen(otherUser: client),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.folder_shared),
                                label: const Text('Shared Files'),
                              ),
                            ),
                          ],
                        ),
                        if (activeAppointment != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Complete Consultation'),
                                    content: const Text(
                                      'Are you sure you want to mark this consultation as completed?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.successColor,
                                        ),
                                        child: const Text('Complete'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true && context.mounted) {
                                  try {
                                    await ref.read(appointmentControllerProvider.notifier)
                                        .completeAppointment(activeAppointment!.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Consultation completed successfully'),
                                          backgroundColor: AppTheme.successColor,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to complete consultation: ${e.toString()}'),
                                          backgroundColor: AppTheme.errorColor,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Complete Consultation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToChat(BuildContext context, WidgetRef ref, String clientId) async {
    try {
      final chatService = ChatService();
      final authState = ref.read(authControllerProvider);
      
      if (authState.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to chat'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Get or create conversation
        final conversation = await chatService.getOrCreateConversation(clientId);
        
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversationId: conversation.id),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open chat: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
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
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

