import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/legal_template_model.dart';

class TemplateService {
  final ApiClient _apiClient = ApiClient();

  Future<List<LegalTemplateModel>> getTemplates({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.templates,
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final templates = response.data['data']['templates'] as List;
        return templates.map((json) => LegalTemplateModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<LegalTemplateModel> getTemplateById(String templateId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.templates}/$templateId');

      if (response.data['success'] == true) {
        return LegalTemplateModel.fromJson(response.data['data']['template']);
      }
      throw Exception(response.data['message'] ?? 'Template not found');
    } catch (e) {
      rethrow;
    }
  }
}

