import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AdminService {
  final ApiClient _apiClient = ApiClient();

  /// Verify a lawyer by their user ID
  Future<UserModel> verifyLawyer(String lawyerId, {double? hourlyRate}) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.adminVerifyLawyer}/$lawyerId/verify',
        data: hourlyRate != null ? {'hourlyRate': hourlyRate} : null,
      );

      if (response.data['success'] == true) {
        final lawyerData = response.data['data']['lawyer'];
        final userData = lawyerData['user'] ?? lawyerData;
        
        return UserModel.fromJson({
          'id': userData['_id'] ?? userData['id'] ?? '',
          'email': userData['email'] ?? '',
          'role': userData['role'] ?? 'LAWYER',
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'phone': userData['phone'],
          'profilePicture': userData['profilePicture'],
          'lawyerProfile': {
            'barLicenseNumber': lawyerData['barLicenseNumber'],
            'specialization': lawyerData['specialization'] ?? [],
            'experience': lawyerData['experience'] ?? 0,
            'hourlyRate': lawyerData['hourlyRate'] ?? 0,
            'bio': lawyerData['bio'],
            'rating': lawyerData['rating'] ?? 0.0,
            'totalReviews': lawyerData['totalReviews'] ?? 0,
            'isVerified': lawyerData['isVerified'] ?? true,
          },
        });
      }
      throw Exception(response.data['message'] ?? 'Failed to verify lawyer');
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users (for admin)
  Future<List<UserModel>> getUsers({
    String? role,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final response = await _apiClient.get(
        ApiConstants.adminUsers,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final usersData = response.data['data']['users'] as List;
        return usersData.map((userData) {
          return UserModel.fromJson({
            'id': userData['_id'] ?? userData['id'] ?? '',
            'email': userData['email'] ?? '',
            'role': userData['role'] ?? '',
            'firstName': userData['firstName'] ?? '',
            'lastName': userData['lastName'] ?? '',
            'phone': userData['phone'],
            'profilePicture': userData['profilePicture'],
            'lawyerProfile': null, // Users list doesn't include profiles
          });
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

