import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/document_service.dart';
import '../../services/chat_service.dart';
import '../../services/appointment_service.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../models/document_model.dart';
import '../../models/appointment_model.dart';
import '../../models/message_model.dart';
import '../../widgets/common/app_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/storage_service.dart';
import '../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../chat/chat_screen.dart';

final documentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final documentService = DocumentService();
  return await documentService.getMyDocuments();
});

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  final _documentService = DocumentService();
  final _appointmentService = AppointmentService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      try {
        await _documentService.uploadDocument(
          file: file,
          onProgress: (sent, total) {
            setState(() {
              _uploadProgress = sent / total;
            });
          },
        );

        if (mounted) {
          ref.invalidate(documentsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareDocument(DocumentModel document) async {
    // Get user's appointments to find lawyers
    final appointmentsAsync = ref.read(appointmentControllerProvider);
    final appointments = await appointmentsAsync.when(
      data: (apps) => apps,
      loading: () => <AppointmentModel>[],
      error: (_, __) => <AppointmentModel>[],
    );

    // Filter to get confirmed appointments with lawyers
    final confirmedAppointments = appointments
        .where((apt) => apt.status == AppointmentStatus.confirmed || apt.status == AppointmentStatus.completed)
        .toList();

    if (confirmedAppointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No confirmed appointments found. Please book an appointment first.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Show dialog to select lawyer/appointment
    final selectedAppointment = await showDialog<AppointmentModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Document'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: confirmedAppointments.length,
            itemBuilder: (context, index) {
              final apt = confirmedAppointments[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(apt.lawyer?.fullName ?? 'Lawyer'),
                subtitle: Text(apt.reason),
                trailing: apt.conversationId != null
                    ? const Icon(Icons.chat, size: 20)
                    : null,
                onTap: () => Navigator.pop(context, apt),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedAppointment == null) return;

    // Share via chat
    try {
      final chatService = ChatService();
      String conversationId;

      if (selectedAppointment.conversationId != null) {
        conversationId = selectedAppointment.conversationId!;
      } else {
        // Create or get conversation
        final currentUser = ref.read(authControllerProvider).user;
        final lawyerId = selectedAppointment.lawyerId;
        
        if (currentUser == null || lawyerId == null) {
          throw Exception('Unable to share document');
        }

        final conversation = await chatService.getOrCreateConversation(lawyerId);
        conversationId = conversation.id;
      }

      await _shareToChat(document, conversationId);
      
      // Optionally navigate to chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversationId: conversationId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _shareToChat(DocumentModel document, String conversationId) async {
    try {
      // Normalize file path - ensure it's relative to uploads directory
      String fileUrl = document.filePath;
      // Remove leading slashes and normalize
      fileUrl = fileUrl.replaceAll('\\', '/');
      if (fileUrl.startsWith('/')) {
        fileUrl = fileUrl.substring(1);
      }
      // Ensure it starts with uploads/ if it's a relative path
      if (!fileUrl.startsWith('uploads/') && !fileUrl.startsWith('http')) {
        // Extract just the filename if path contains uploads
        final parts = fileUrl.split('/');
        final uploadsIndex = parts.indexOf('uploads');
        if (uploadsIndex >= 0 && uploadsIndex < parts.length - 1) {
          fileUrl = parts.sublist(uploadsIndex).join('/');
        } else {
          // Assume it's in uploads directory
          fileUrl = 'uploads/${parts.last}';
        }
      }
      
      // Use chat controller to send message
      await ref.read(chatControllerProvider(conversationId).notifier).sendMessage(
        document.originalName,
        fileUrl: fileUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document shared successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context); // Close share dialog if open
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _downloadDocument(DocumentModel document) async {
    try {
      // For Android 10+ (API 29+), we can use scoped storage without permission
      // Try to use Downloads directory (works without permission on Android 10+)
      if (Platform.isAndroid) {
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
          // If scoped storage doesn't work, use app directory (no permission needed)
          print('Using app directory for download: $e');
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

      // Construct file URL
      String fileUrl;
      if (document.filePath.startsWith('http://') || document.filePath.startsWith('https://')) {
        fileUrl = document.filePath;
      } else {
        final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
        final normalizedPath = document.filePath.replaceAll('\\', '/');
        fileUrl = '$baseUrlWithoutApi/$normalizedPath';
      }

      // Fetch file with authentication
      final apiClient = ApiClient();
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
        // Get download directory (same logic as chat screen - no permission needed)
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
        final file = File('${directory.path}/${document.originalName}');
        await file.writeAsBytes(response.data as Uint8List);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to Downloads/${document.originalName}'),
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

  Future<void> _deleteDocument(DocumentModel document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.originalName}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _documentService.deleteDocument(document.id);
        if (mounted) {
          ref.invalidate(documentsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  IconData _getFileIcon(String fileName, String mimeType) {
    final lowerFileName = fileName.toLowerCase();
    final ext = lowerFileName.split('.').last;
    
    if (mimeType.startsWith('image/')) return Icons.image;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['txt', 'rtf'].contains(ext)) return Icons.text_snippet;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Icons.archive;
    if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'].contains(ext)) return Icons.video_file;
    if (['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a'].contains(ext)) return Icons.audiotrack;
    if (['js', 'ts', 'jsx', 'tsx', 'py', 'java', 'cpp', 'c', 'cs', 'php', 'rb', 'go', 'rs', 'swift', 'kt', 'dart'].contains(ext)) return Icons.code;
    if (['html', 'htm', 'css', 'xml', 'json', 'yaml', 'yml'].contains(ext)) return Icons.code;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _uploadFile,
              tooltip: 'Upload File',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(documentsProvider);
        },
        child: documentsAsync.when(
          data: (documents) {
            if (documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the upload button to add files',
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
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getFileIcon(document.originalName, document.mimeType),
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.originalName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${document.fileSizeFormatted} • ${document.category.value.replaceAll('_', ' ').toUpperCase()}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                if (document.description != null && document.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    document.description!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'share':
                                  _shareDocument(document);
                                  break;
                                case 'download':
                                  _downloadDocument(document);
                                  break;
                                case 'delete':
                                  _deleteDocument(document);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, size: 20),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'download',
                                child: Row(
                                  children: [
                                    Icon(Icons.download, size: 20),
                                    SizedBox(width: 8),
                                    Text('Download'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded ${dateFormat.format(document.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
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
                  'Error loading documents',
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
                    ref.invalidate(documentsProvider);
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
}

