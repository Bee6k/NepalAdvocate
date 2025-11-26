import 'dart:io';
import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/document_model.dart';

class DocumentService {
  final ApiClient _apiClient = ApiClient();

  Future<DocumentModel> uploadDocument({
    required File file,
    String? appointmentId,
    String? description,
    DocumentCategory category = DocumentCategory.other,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      final response = await _apiClient.uploadFile(
        ApiConstants.uploadDocument,
        file.path,
        additionalData: {
          if (appointmentId != null) 'appointmentId': appointmentId,
          if (description != null) 'description': description,
          'category': category.value,
        },
        onSendProgress: onProgress != null
            ? (sent, total) => onProgress(sent, total)
            : null,
      );

      if (response.data['success'] == true) {
        return DocumentModel.fromJson(response.data['data']['document']);
      }
      throw Exception(response.data['message'] ?? 'Failed to upload document');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DocumentModel>> getMyDocuments({
    String? appointmentId,
    DocumentCategory? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.myDocuments,
        queryParameters: {
          if (appointmentId != null) 'appointmentId': appointmentId,
          if (category != null) 'category': category.value,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final documents = response.data['data']['documents'] as List;
        return documents.map((json) => DocumentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentModel> getDocument(String documentId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.documents}/$documentId');

      if (response.data['success'] == true) {
        return DocumentModel.fromJson(response.data['data']['document']);
      }
      throw Exception(response.data['message'] ?? 'Document not found');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _apiClient.delete('${ApiConstants.documents}/$documentId');
    } catch (e) {
      rethrow;
    }
  }

  Future<String> downloadDocument(String documentId) async {
    try {
      await _apiClient.get('${ApiConstants.documents}/$documentId/download');
      // Handle file download - this would need file handling logic
      return '';
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SharedFileModel>> getSharedDocuments({
    required String userId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.sharedDocuments}/$userId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final files = response.data['data']['files'] as List;
        return files.map((json) => SharedFileModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

class SharedFileModel {
  final String id;
  final String type; // 'document' or 'chat'
  final String fileName;
  final String originalName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String? description;
  final DocumentCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedFileModel({
    required this.id,
    required this.type,
    required this.fileName,
    required this.originalName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    this.description,
    this.category = DocumentCategory.other,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage {
    return mimeType.startsWith('image/');
  }

  factory SharedFileModel.fromJson(Map<String, dynamic> json) {
    return SharedFileModel(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? 'document',
      fileName: json['fileName'] ?? '',
      originalName: json['originalName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      mimeType: json['mimeType'] ?? 'application/octet-stream',
      description: json['description'],
      category: DocumentCategory.fromString(json['category'] ?? 'other'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['createdAt']),
    );
  }
}

