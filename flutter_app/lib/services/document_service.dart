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
}

