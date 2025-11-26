import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';

class VerificationService {
  final ApiClient _apiClient = ApiClient();

  /// Submit a verification request
  Future<void> submitVerificationRequest() async {
    try {
      final response = await _apiClient.post(
        ApiConstants.submitVerificationRequest,
      );

      if (response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Failed to submit verification request');
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification request status
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getVerificationStatus,
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Failed to get verification status');
    } catch (e) {
      rethrow;
    }
  }
}

