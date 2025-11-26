import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/verified_avatar.dart';
import '../clients/shared_files_screen.dart';
import '../../services/chat_service.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/storage_service.dart';
import '../../core/constants/api_constants.dart';

class ConsultationDetailScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  final UserModel? otherUser;

  const ConsultationDetailScreen({
    super.key,
    required this.appointment,
    required this.otherUser,
  });

  @override
  ConsumerState<ConsultationDetailScreen> createState() => _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends ConsumerState<ConsultationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser?.fullName ?? 'Consultation Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.folder_shared), text: 'Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(context, dateFormat, timeFormat),
          _buildChatTab(context),
          _buildFilesTab(context),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, DateFormat dateFormat, DateFormat timeFormat) {
    final currentUser = ref.read(authControllerProvider).user;
    final isLawyer = currentUser?.role == 'LAWYER';
    final userLabel = isLawyer ? 'Client' : 'Lawyer';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client/Lawyer Info Card
          AppCard(
            child: Column(
              children: [
                if (widget.otherUser != null) ...[
                  VerifiedAvatar(
                    imageUrl: widget.otherUser!.profilePicture,
                    name: widget.otherUser!.fullName,
                    radius: 40,
                    isVerified: widget.otherUser!.lawyerProfile?.isVerified ?? false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.otherUser!.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (widget.otherUser!.lawyerProfile?.isVerified == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Lawyer',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    userLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (widget.otherUser!.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.otherUser!.email!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                  if (widget.otherUser!.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.otherUser!.phone!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Appointment Details
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.description,
                  'Reason',
                  widget.appointment.reason,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.calendar_today,
                  'Date',
                  widget.appointment.confirmedDate != null
                      ? dateFormat.format(widget.appointment.confirmedDate!)
                      : dateFormat.format(widget.appointment.proposedDate),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.access_time,
                  'Time',
                  widget.appointment.confirmedTime ?? widget.appointment.proposedTime,
                ),
                if (widget.appointment.notes != null && widget.appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    Icons.note,
                    'Notes',
                    widget.appointment.notes!,
                  ),
                ],
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.check_circle,
                  'Status',
                  'Completed',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  Icons.update,
                  'Completed On',
                  dateFormat.format(widget.appointment.updatedAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getConversationId(),
      builder: (context, conversationSnapshot) {
        if (conversationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (conversationSnapshot.hasError) {
          return Center(
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
                  'Error loading chat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  conversationSnapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final conversationId = conversationSnapshot.data;
        if (conversationId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversation found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'No messages were exchanged during this consultation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        // Fetch and display messages
        return FutureBuilder<List<MessageModel>>(
          future: ChatService().getMessages(conversationId, limit: 100),
          builder: (context, messagesSnapshot) {
            if (messagesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (messagesSnapshot.hasError) {
              return Center(
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
                      'Error loading messages',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      messagesSnapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.errorColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final messages = messagesSnapshot.data ?? [];
            final currentUser = ref.read(authControllerProvider).user;

            if (messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No messages',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No messages were exchanged during this consultation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final currentUserId = currentUser?.id?.toString() ?? '';
                final messageSenderId = message.senderId?.toString() ?? '';
                final isMe = currentUserId.isNotEmpty &&
                    messageSenderId.isNotEmpty &&
                    currentUserId == messageSenderId;

                return _MessageBubble(
                  message: message,
                  isMe: isMe,
                  currentUser: currentUser,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilesTab(BuildContext context) {
    if (widget.otherUser == null) {
      return const Center(
        child: Text('User information not available'),
      );
    }

    return SharedFilesScreen(otherUser: widget.otherUser!);
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _getConversationId() async {
    try {
      if (widget.appointment.conversationId != null) {
        return widget.appointment.conversationId;
      }

      // Try to get conversation (don't create for history)
      if (widget.otherUser != null) {
        final chatService = ChatService();
        try {
          final conversation = await chatService.getOrCreateConversation(widget.otherUser!.id);
          return conversation.id;
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final UserModel? currentUser;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.currentUser,
  });

  String _getFileUrl(String filePath) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = filePath.replaceAll('\\', '/');
    return '$baseUrlWithoutApi/$normalizedPath';
  }

  bool _isImageFile(String? mimeType, String? fileName) {
    if (mimeType != null && mimeType.startsWith('image/')) return true;
    if (fileName != null) {
      final ext = fileName.toLowerCase().split('.').last;
      return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            VerifiedAvatar(
              imageUrl: message.sender?.profilePicture,
              name: message.sender?.fullName,
              radius: 16,
              isVerified: false,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: message.messageType == MessageType.file && message.fileUrl != null
                ? Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      _FileMessageWidget(
                        fileUrl: message.fileUrl!,
                        fileName: message.content,
                        mimeType: null,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          dateFormat.format(message.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: AppConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: isMe 
                          ? const Color(0xFF1A7A7E) // Softer, darker teal for own messages
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isMe ? Colors.white : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(message.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isMe
                                    ? Colors.white70
                                    : AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            VerifiedAvatar(
              imageUrl: currentUser?.profilePicture,
              name: currentUser?.fullName,
              radius: 16,
              isVerified: currentUser?.lawyerProfile?.isVerified ?? false,
            ),
          ],
        ],
      ),
    );
  }
}

class _FileMessageWidget extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final String? mimeType;

  const _FileMessageWidget({
    required this.fileUrl,
    required this.fileName,
    this.mimeType,
  });

  String _getFileUrl() {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = fileUrl.replaceAll('\\', '/');
    return '$baseUrlWithoutApi/$normalizedPath';
  }

  bool _isImageFile() {
    if (mimeType != null && mimeType!.startsWith('image/')) return true;
    final ext = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'ico'].contains(ext);
  }

  IconData _getFileIcon() {
    if (_isImageFile()) return Icons.image;
    final ext = fileName.toLowerCase().split('.').last;
    
    // Documents
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['txt', 'rtf'].contains(ext)) return Icons.text_snippet;
    
    // Archives
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Icons.archive;
    
    // Media
    if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'].contains(ext)) return Icons.video_file;
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(ext)) return Icons.audiotrack;
    
    // Code
    if (['js', 'ts', 'jsx', 'tsx', 'py', 'java', 'cpp', 'c', 'cs', 'php', 'rb', 'go', 'rs', 'swift', 'kt', 'dart'].contains(ext)) return Icons.code;
    if (['html', 'htm', 'css', 'xml', 'json', 'yaml', 'yml'].contains(ext)) return Icons.code;
    
    // Default
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile();

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
            maxHeight: 200,
          ),
          child: _AuthenticatedImage(
            imageUrl: _getFileUrl(),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(),
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              fileName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const _AuthenticatedImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<_AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<_AuthenticatedImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final storage = StorageService();
      final token = await storage.getToken();
      if (token == null) {
        setState(() {
          _error = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final apiClient = ApiClient();
      final response = await apiClient.dio.get(
        widget.imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null) {
        setState(() {
          _imageBytes = response.data as Uint8List;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 200,
        height: 200,
        color: AppTheme.cardColor,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null || _imageBytes == null) {
      return Container(
        width: 200,
        height: 200,
        color: AppTheme.cardColor,
        child: Icon(
          Icons.broken_image,
          color: AppTheme.textSecondary,
          size: 48,
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      width: 200,
      height: 200,
    );
  }
}

