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

  String _formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y • h:mm a').format(date);
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'APPOINTMENT_REQUEST':
        return 'Appointment Request';
      case 'APPOINTMENT_PROPOSED':
        return 'Appointment Proposed';
      case 'APPOINTMENT_CONFIRMED':
        return 'Appointment Confirmed';
      case 'APPOINTMENT_CANCELLED':
        return 'Appointment Cancelled';
      case 'MESSAGE':
        return 'New Message';
      case 'DOCUMENT_UPLOADED':
        return 'Document Uploaded';
      case 'SYSTEM':
        return 'System Notification';
      case 'VERIFICATION_APPROVED':
        return 'Verification Approved';
      case 'VERIFICATION_REJECTED':
        return 'Verification Rejected';
      case 'VERIFICATION_REQUEST':
        return 'Verification Request';
      default:
        return 'Notification';
    }
  }

  Future<void> _showNotificationDetails(NotificationModel notification) async {
    // Mark as read when viewing details
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
                vertical: AppConstants.spacingM,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getNotificationTypeLabel(notification.type),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              height: 1.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingL),
                    // Details section
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildDetailRow(
                      context,
                      Icons.access_time,
                      'Received',
                      _formatFullDate(notification.createdAt),
                    ),
                    if (notification.readAt != null) ...[
                      const SizedBox(height: AppConstants.spacingS),
                      _buildDetailRow(
                        context,
                        Icons.check_circle_outline,
                        'Read',
                        _formatFullDate(notification.readAt!),
                      ),
                    ],
                    if (notification.relatedId != null) ...[
                      const SizedBox(height: AppConstants.spacingS),
                      _buildDetailRow(
                        context,
                        Icons.link,
                        'Related',
                        '${notification.relatedType?.toUpperCase() ?? 'Item'}: ${notification.relatedId}',
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacingS),
                    _buildDetailRow(
                      context,
                      notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                      'Status',
                      notification.isRead ? 'Read' : 'Unread',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
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
                    onTap: _actionInProgress[notification.id] == true
                        ? null // Disable tap if action is in progress
                        : () => _showNotificationDetails(notification),
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
                                    const SizedBox(height: 16),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppTheme.textSecondary.withOpacity(0.1),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceColor.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.textSecondary.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.touch_app_outlined,
                                                size: 16,
                                                color: AppTheme.accentColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Choose an action:',
                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                      color: AppTheme.textSecondary,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.successColor.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
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
                                                        strokeWidth: 2.5,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    )
                                                  : const Icon(Icons.check_circle_outline, size: 20),
                                              label: Text(
                                                _actionInProgress[notification.id] == true ? 'Accepting...' : 'Accept',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.successColor,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.errorColor.withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: OutlinedButton.icon(
                                              onPressed: _actionInProgress[notification.id] == true
                                                  ? null
                                                  : () async {
                                                      final shouldCancel = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          backgroundColor: AppTheme.cardColor,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(16),
                                                          ),
                                                          title: Text(
                                                            'Cancel Appointment',
                                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                          ),
                                                          content: Text(
                                                            'Are you sure you want to cancel this appointment? This action cannot be undone.',
                                                            style: Theme.of(context).textTheme.bodyMedium,
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              style: TextButton.styleFrom(
                                                                foregroundColor: AppTheme.textSecondary,
                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                              ),
                                                              child: const Text('No'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: AppTheme.errorColor,
                                                                foregroundColor: Colors.white,
                                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(10),
                                                                ),
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
                                                        strokeWidth: 2.5,
                                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorColor),
                                                      ),
                                                    )
                                                  : const Icon(Icons.close, size: 20),
                                              label: Text(
                                                _actionInProgress[notification.id] == true ? 'Cancelling...' : 'Cancel',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                  color: AppTheme.errorColor,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.errorColor,
                                                side: BorderSide.none,
                                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                            ],
                                          ),
                                        ],
                                      ),
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

