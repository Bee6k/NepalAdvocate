import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/call_service.dart';
import '../../services/document_service.dart';
import '../../views/calls/call_screen.dart';
import '../../widgets/common/verified_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppConstants.animationMedium,
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await ref.read(chatControllerProvider(widget.conversationId).notifier).sendMessage(content);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _sendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Upload file
        final apiClient = ApiClient();
        final response = await apiClient.uploadFile(
          ApiConstants.uploadDocument,
          file.path,
          additionalData: {
            'conversationId': widget.conversationId,
          },
        );

        if (response.data['success'] == true) {
          final document = response.data['data']['document'];
          final fileUrl = document['filePath'] ?? document['fileName'];
          
          // Send file message
          await ref.read(chatControllerProvider(widget.conversationId).notifier).sendMessage(
            fileName,
            fileUrl: fileUrl,
          );
          
          _scrollToBottom();
        } else {
          throw Exception(response.data['message'] ?? 'Failed to upload file');
        }
      } finally {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  String? _getOtherUserId(List<MessageModel> messages, String? currentUserId) {
    if (messages.isEmpty || currentUserId == null) return null;
    
    // Find a message from the other user
    for (final message in messages) {
      if (message.senderId.toString() != currentUserId.toString()) {
        return message.senderId.toString();
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatControllerProvider(widget.conversationId));
    final currentUser = ref.watch(authControllerProvider).user;

    // Scroll to bottom when new messages arrive
    messagesAsync.whenData((messages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });

    // Get other user ID from messages
    String? otherUserId;
    messagesAsync.whenData((messages) {
      otherUserId = _getOtherUserId(messages, currentUser?.id);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          // Voice call button
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: otherUserId != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallScreen(
                          conversationId: widget.conversationId,
                          otherUserId: otherUserId!,
                          callType: CallType.voice,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          // Video call button
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: otherUserId != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallScreen(
                          conversationId: widget.conversationId,
                          otherUserId: otherUserId!,
                          callType: CallType.video,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    
                    // Compare senderId with current user ID (handle both string and ObjectId formats)
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                // Check if it's an appointment confirmation error
                final errorStr = error.toString().toLowerCase();
                final isAppointmentError = errorStr.contains('appointment') || 
                                         errorStr.contains('confirmed') ||
                                         errorStr.contains('403');
                
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isAppointmentError ? Icons.event_busy : Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAppointmentError 
                            ? 'Chat Not Available'
                            : 'Error Loading Messages',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAppointmentError
                            ? 'Chat is only available after your appointment is confirmed by the lawyer. Please wait for the lawyer to confirm your appointment request.'
                            : error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onFilePick: _sendFile,
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
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
            child: message.messageType == MessageType.file && 
                   message.fileUrl != null && 
                   message.fileUrl!.isNotEmpty
                ? Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      _FileMessageWidget(fileUrl: message.fileUrl!),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
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
                          style: TextStyle(
                            color: isMe ? AppTheme.backgroundColor : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? AppTheme.backgroundColor.withValues(alpha: 0.7)
                                : AppTheme.textSecondary,
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

class _ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onFilePick;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    this.onFilePick,
  });

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.cardColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onFilePick != null)
            IconButton(
              onPressed: widget.onFilePick,
              icon: const Icon(Icons.attach_file, color: AppTheme.primaryColor),
              tooltip: 'Attach file',
            ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) {
                if (_hasText) {
                  widget.onSend();
                }
              },
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          IconButton(
            onPressed: _hasText ? widget.onSend : null,
            icon: Icon(
              Icons.send,
              color: _hasText ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _hasText
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : AppTheme.cardColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileMessageWidget extends StatefulWidget {
  final String fileUrl;

  const _FileMessageWidget({required this.fileUrl});

  @override
  State<_FileMessageWidget> createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<_FileMessageWidget> {
  String _getImageUrl() {
    // Construct full URL for the image
    // If fileUrl already contains http, use it as is
    if (widget.fileUrl.startsWith('http://') || widget.fileUrl.startsWith('https://')) {
      return widget.fileUrl;
    }
    // Otherwise, construct URL using baseUrl
    // Remove /api from baseUrl and append the file path
    // The backend serves files at /uploads with authentication
    final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
    // Normalize path separators (handle both / and \)
    final normalizedPath = widget.fileUrl.replaceAll('\\', '/');
    return '$baseUrlWithoutApi/$normalizedPath';
  }

  bool _isImageFile(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    return lowerFileName.endsWith('.jpg') ||
        lowerFileName.endsWith('.jpeg') ||
        lowerFileName.endsWith('.png') ||
        lowerFileName.endsWith('.gif') ||
        lowerFileName.endsWith('.webp') ||
        lowerFileName.endsWith('.bmp') ||
        lowerFileName.endsWith('.svg') ||
        lowerFileName.endsWith('.ico');
  }

  IconData _getFileIcon(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    final ext = lowerFileName.split('.').last;
    
    // Images
    if (_isImageFile(fileName)) return Icons.image;
    
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

  Future<void> _downloadFile(String fileName) async {
    try {
      // For Android 10+ (API 29+), we can use scoped storage without permission
      // For Android 13+ (API 33+), we need manageExternalStorage permission for Downloads
      if (Platform.isAndroid) {
        final isImage = _isImageFile(fileName);
        
        // Try to use Downloads directory (works without permission on Android 10+)
        // If that fails, request manageExternalStorage permission (Android 11+)
        try {
          // First try to access Downloads without permission (scoped storage)
          final directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // Try alternative path
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              final downloadDir = Directory('${externalDir.path}/Download');
              if (!await downloadDir.exists()) {
                await downloadDir.create(recursive: true);
              }
            }
          }
        } catch (e) {
          // If scoped storage doesn't work, try requesting manageExternalStorage
          try {
            final status = await Permission.manageExternalStorage.request();
            if (!status.isGranted) {
              // Fallback: try using app's external storage directory
              print('ManageExternalStorage not granted, using app directory');
            }
          } catch (e2) {
            // If manageExternalStorage is not available, use app directory
            print('Using app directory for download: $e2');
          }
        }
      }

      // Get token for authentication
      final storage = StorageService();
      final token = await storage.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Fetch file with authentication
      final apiClient = ApiClient();
      final fileUrl = _getImageUrl();
      final response = await apiClient.dio.get(
        fileUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data != null) {
        // Get download directory
        Directory? directory;
        if (Platform.isAndroid) {
          try {
            // Try Downloads directory first (works with scoped storage on Android 10+)
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              // Try alternative Downloads path
              final externalDir = await getExternalStorageDirectory();
              if (externalDir != null) {
                // Use app's external storage with Downloads subfolder
                directory = Directory('${externalDir.path}/Download');
              } else {
                // Fallback to app documents
                directory = await getApplicationDocumentsDirectory();
              }
            }
          } catch (e) {
            // Fallback to app's external storage
            try {
              final externalDir = await getExternalStorageDirectory();
              if (externalDir != null) {
                directory = Directory('${externalDir.path}/Download');
              } else {
                directory = await getApplicationDocumentsDirectory();
              }
            } catch (e2) {
              directory = await getApplicationDocumentsDirectory();
            }
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        // Ensure directory exists
        if (directory != null && !await directory.exists()) {
          try {
            await directory.create(recursive: true);
          } catch (e) {
            // If we can't create Downloads, use app directory
            directory = await getApplicationDocumentsDirectory();
            await directory.create(recursive: true);
          }
        }

        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        }

        // Save file
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.data as Uint8List);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to Downloads/$fileName'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _downloadImage() async {
    final fileName = widget.fileUrl.split('/').last.split('\\').last;
    await _downloadFile(fileName);
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty or null fileUrl
    if (widget.fileUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final fileName = widget.fileUrl.split('/').last.split('\\').last;
    final isImage = _isImageFile(fileName);

    if (isImage) {
      // Display image inline with authentication
      return GestureDetector(
        onTap: () {
          // Show full screen image viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _ImageViewerScreen(
                imageUrl: _getImageUrl(),
                fileName: fileName,
                fileUrl: widget.fileUrl,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            child: Stack(
              children: [
                _AuthenticatedImage(
                  imageUrl: _getImageUrl(),
                  width: 250,
                  height: 300,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      final fileName = widget.fileUrl.split('/').last.split('\\').last;
                      _downloadFile(fileName);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 16,
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

    // Non-image file - show file card without background
    return InkWell(
      onTap: () => _downloadFile(fileName),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(fileName),
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to download',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  const _AuthenticatedImage({
    required this.imageUrl,
    this.width,
    this.height,
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
        width: widget.width,
        height: widget.height ?? 200,
        color: AppTheme.cardColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _imageBytes == null) {
      return Container(
        width: widget.width,
        height: widget.height ?? 200,
        color: AppTheme.cardColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load image',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String fileName;
  final String fileUrl;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.fileName,
    required this.fileUrl,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
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

  Future<void> _downloadImage() async {
    // Ensure image is loaded
    if (_imageBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image not loaded'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    try {
      // Get download directory (same logic as _downloadFile - no permission needed for scoped storage)
      Directory? directory;
      if (Platform.isAndroid) {
        try {
          // Try Downloads directory first (works with scoped storage on Android 10+)
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            // Try alternative Downloads path
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              directory = Directory('${externalDir.path}/Download');
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
          }
        } catch (e) {
          // Fallback to app's external storage
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              directory = Directory('${externalDir.path}/Download');
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
          } catch (e2) {
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (directory != null && !await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
          await directory.create(recursive: true);
        }
      }

      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      // Save file
      final file = File('${directory.path}/${widget.fileName}');
      await file.writeAsBytes(_imageBytes!);

      if (mounted) {
        final savePath = directory.path.replaceAll('\\', '/');
        final isDownloads = savePath.contains('Download');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDownloads 
                ? 'Image saved to Downloads/${widget.fileName}'
                : 'Image saved to $savePath/${widget.fileName}',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadImage,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null || _imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: AppTheme.errorColor,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Failed to load image',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
      ),
    );
  }
}
