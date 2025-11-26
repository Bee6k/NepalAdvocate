import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/app_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Map<String, bool> _actionInProgress = {}; // Track which notifications have actions in progress

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(notificationServiceProvider).clearAll();
        ref.invalidate(notificationsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing notifications: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await ref.read(notificationServiceProvider).markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notification as read: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'APPOINTMENT_REQUEST':
      case 'APPOINTMENT_PROPOSED':
      case 'APPOINTMENT_CONFIRMED':
      case 'APPOINTMENT_CANCELLED':
        return Icons.event;
      case 'MESSAGE':
        return Icons.message;
      case 'DOCUMENT_UPLOADED':
        return Icons.description;
      case 'SYSTEM':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'APPOINTMENT_CONFIRMED':
        return AppTheme.successColor;
      case 'APPOINTMENT_PROPOSED':
        return AppTheme.accentColor;
      case 'APPOINTMENT_CANCELLED':
        return AppTheme.errorColor;
      case 'MESSAGE':
        return AppTheme.primaryColor;
      case 'DOCUMENT_UPLOADED':
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear All',
                onPressed: _clearAllNotifications,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final icon = _getNotificationIcon(notification.type);
                final color = _getNotificationColor(notification.type);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                  child: AppCard(
                    onTap: notification.type == 'APPOINTMENT_PROPOSED' && 
                           !notification.isRead &&
                           _actionInProgress[notification.id] != true
                        ? null // Disable tap if it has action buttons
                        : () => _markAsRead(notification),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: notification.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notification.message,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: notification.isRead
                                              ? AppTheme.textSecondary
                                              : AppTheme.textPrimary,
                                          fontSize: 14,
                                        ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(notification.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                  // Show action buttons for APPOINTMENT_PROPOSED notifications
                                  // Only show if action is not in progress and notification is not read
                                  if (notification.type == 'APPOINTMENT_PROPOSED' && 
                                      notification.relatedId != null &&
                                      notification.relatedType == 'appointment' &&
                                      (_actionInProgress[notification.id] != true) &&
                                      !notification.isRead) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _actionInProgress[notification.id] == true
                                                ? null
                                                : () async {
                                                    setState(() {
                                                      _actionInProgress[notification.id] = true;
                                                    });
                                                    
                                                    await _markAsRead(notification);
                                                    
                                                    try {
                                                      // Accept the proposed time
                                                      await ref.read(appointmentControllerProvider.notifier).confirmAppointment(
                                                        notification.relatedId!,
                                                      );
                                                      
                                                      // Refresh appointments list and consultation history
                                                      ref.read(appointmentControllerProvider.notifier).loadAppointments();
                                                      ref.invalidate(consultationHistoryProvider);
                                                      
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Appointment time accepted! The lawyer will be notified.'),
                                                            backgroundColor: AppTheme.successColor,
                                                            duration: Duration(seconds: 3),
                                                          ),
                                                        );
                                                        
                                                        // Refresh notifications
                                                        ref.invalidate(notificationsProvider);
                                                        
                                                        // Remove from in-progress
                                                        setState(() {
                                                          _actionInProgress.remove(notification.id);
                                                        });
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Failed to accept: ${e.toString()}'),
                                                            backgroundColor: AppTheme.errorColor,
                                                            duration: const Duration(seconds: 3),
                                                          ),
                                                        );
                                                        
                                                        setState(() {
                                                          _actionInProgress.remove(notification.id);
                                                        });
                                                      }
                                                    }
                                                  },
                                            icon: _actionInProgress[notification.id] == true
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Icon(Icons.check, size: 18),
                                            label: Text(_actionInProgress[notification.id] == true ? 'Accepting...' : 'Accept Time'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.successColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _actionInProgress[notification.id] == true
                                                ? null
                                                : () async {
                                                    final shouldCancel = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Cancel Appointment'),
                                                        content: const Text(
                                                          'Are you sure you want to cancel this appointment? This action cannot be undone.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context, false),
                                                            child: const Text('No'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.pop(context, true),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: AppTheme.errorColor,
                                                            ),
                                                            child: const Text('Yes, Cancel'),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (shouldCancel == true && mounted) {
                                                      setState(() {
                                                        _actionInProgress[notification.id] = true;
                                                      });
                                                      
                                                      await _markAsRead(notification);
                                                      
                                                      try {
                                                        // Cancel the appointment
                                                        await ref.read(appointmentControllerProvider.notifier).cancelAppointment(
                                                          notification.relatedId!,
                                                        );
                                                        
                                                        // Refresh appointments list and consultation history
                                                        ref.read(appointmentControllerProvider.notifier).loadAppointments();
                                                        ref.invalidate(consultationHistoryProvider);
                                                        
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Appointment cancelled successfully.'),
                                                              backgroundColor: AppTheme.errorColor,
                                                              duration: Duration(seconds: 3),
                                                            ),
                                                          );
                                                          
                                                          // Refresh notifications
                                                          ref.invalidate(notificationsProvider);
                                                          
                                                          // Remove from in-progress
                                                          setState(() {
                                                            _actionInProgress.remove(notification.id);
                                                          });
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Failed to cancel: ${e.toString()}'),
                                                              backgroundColor: AppTheme.errorColor,
                                                              duration: const Duration(seconds: 3),
                                                            ),
                                                          );
                                                          
                                                          setState(() {
                                                            _actionInProgress.remove(notification.id);
                                                          });
                                                        }
                                                      }
                                                    }
                                                  },
                                            icon: _actionInProgress[notification.id] == true
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                                    ),
                                                  )
                                                : const Icon(Icons.cancel, size: 18),
                                            label: Text(_actionInProgress[notification.id] == true ? 'Cancelling...' : 'Cancel'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.errorColor,
                                              side: BorderSide(color: AppTheme.errorColor),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
                'Error loading notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.errorColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

