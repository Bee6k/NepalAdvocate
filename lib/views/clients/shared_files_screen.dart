import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../services/document_service.dart';
import '../../models/document_model.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_service.dart';
import '../../core/utils/api_client.dart';
import '../../widgets/common/app_card.dart';

class SharedFilesScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;

  const SharedFilesScreen({super.key, required this.otherUser});

  @override
  ConsumerState<SharedFilesScreen> createState() => _SharedFilesScreenState();
}

class _SharedFilesScreenState extends ConsumerState<SharedFilesScreen> {
  final DocumentService _documentService = DocumentService();
  List<SharedFileModel> _files = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedDocuments();
  }

  Future<void> _loadSharedDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final files = await _documentService.getSharedDocuments(
        userId: widget.otherUser.id,
      );
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getFileUrl(String filePath) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = filePath.replaceAll('\\', '/');
    return '$baseUrlWithoutApi/$normalizedPath';
  }

  Future<void> _downloadFile(SharedFileModel file) async {
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

      // Fetch file with authentication
      final apiClient = ApiClient();
      final fileUrl = _getFileUrl(file.filePath);
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
        final savedFile = File('${directory.path}/${file.originalName}');
        await savedFile.writeAsBytes(response.data as Uint8List);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved to Downloads/${file.originalName}'),
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

  void _viewImage(SharedFileModel file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          imageUrl: _getFileUrl(file.filePath),
          fileName: file.originalName,
        ),
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shared Files with ${widget.otherUser.fullName}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSharedDocuments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
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
                          'Error loading files',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSharedDocuments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _files.isEmpty
                    ? Center(
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
                              'No shared files',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Files shared between you and ${widget.otherUser.fullName} will appear here',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

                          return AppCard(
                            onTap: file.isImage ? () => _viewImage(file) : () => _downloadFile(file),
                            child: Row(
                              children: [
                                if (file.isImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: AppTheme.cardColor,
                                      child: _ImageThumbnail(
                                        imageUrl: _getFileUrl(file.filePath),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getFileIcon(file.mimeType),
                                      color: AppTheme.primaryColor,
                                      size: 32,
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              file.originalName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (file.type == 'chat')
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Chat',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.primaryColor,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        file.fileSizeFormatted,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateFormat.format(file.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(file.isImage ? Icons.visibility : Icons.download),
                                  color: AppTheme.primaryColor,
                                  onPressed: file.isImage
                                      ? () => _viewImage(file)
                                      : () => _downloadFile(file),
                                  tooltip: file.isImage ? 'View' : 'Download',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _ImageThumbnail extends StatefulWidget {
  final String imageUrl;

  const _ImageThumbnail({required this.imageUrl});

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

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
        setState(() => _isLoading = false);
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_imageBytes == null) {
      return Icon(Icons.broken_image, color: AppTheme.textSecondary, size: 24);
    }

    return Image.memory(
      _imageBytes!,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String fileName;

  const _ImageViewerScreen({
    required this.imageUrl,
    required this.fileName,
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
    try {
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

      // Get download directory (same logic as other download functions - no permission needed)
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

