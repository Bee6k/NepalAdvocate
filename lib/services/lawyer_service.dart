import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class LawyerService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UserModel>> getLawyers({
    String? search,
    String? specialization,
    double? minRating,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (specialization != null && specialization.isNotEmpty) {
        queryParams['specialization'] = specialization;
      }
      if (minRating != null) {
        queryParams['minRating'] = minRating;
      }

      final response = await _apiClient.get(
        ApiConstants.lawyers,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final lawyersData = response.data['data']['lawyers'] as List;
        return lawyersData.map((lawyerData) {
          try {
            // Backend returns lawyer with user and profile data combined
            // user field might be an object or just an ID string
            final userField = lawyerData['user'];
            Map<String, dynamic>? userData;
            
            // Check if user is a Map/object
            if (userField is Map) {
              userData = Map<String, dynamic>.from(userField);
            } else {
              userData = null;
            }
            
            // Extract user ID - handle both object and string cases
            String userId;
            if (userData != null && userData.containsKey('_id')) {
              userId = (userData['_id'] ?? userData['id'] ?? '').toString();
            } else if (userField != null && userField is! Map) {
              // user is just an ID string
              userId = userField.toString();
            } else {
              // Fallback to _id from lawyerData
              userId = (lawyerData['_id'] ?? '').toString();
            }
            
            // Safely extract profile data
            final profileData = <String, dynamic>{};
            bool hasProfile = false;
            
            if (lawyerData['barLicenseNumber'] != null || 
                lawyerData['specialization'] != null ||
                lawyerData['hourlyRate'] != null) {
              hasProfile = true;
              
              // Safely handle specialization
              dynamic specialization = lawyerData['specialization'];
              if (specialization == null) {
                profileData['specialization'] = [];
              } else if (specialization is List) {
                profileData['specialization'] = specialization.map((e) => e.toString()).toList();
              } else if (specialization is String) {
                profileData['specialization'] = [specialization];
              } else {
                profileData['specialization'] = [];
              }
              
              // Safely handle other fields
              profileData['barLicenseNumber'] = lawyerData['barLicenseNumber']?.toString();
              profileData['experience'] = lawyerData['experience'];
              profileData['hourlyRate'] = lawyerData['hourlyRate'];
              profileData['bio'] = lawyerData['bio']?.toString();
              profileData['rating'] = lawyerData['rating'];
              profileData['totalReviews'] = lawyerData['totalReviews'];
              profileData['isVerified'] = lawyerData['isVerified'];
            }
            
            // Build user JSON safely
            // When user is just an ID, the backend should still have firstName, lastName etc at root level
            // But if user is an object, use that first, then fallback to root level
            final userJson = <String, dynamic>{
              'id': userId,
              'email': (userData?['email'] ?? lawyerData['email'] ?? '').toString(),
              'role': (userData?['role'] ?? lawyerData['role'] ?? 'LAWYER').toString(),
              'firstName': (userData?['firstName'] ?? lawyerData['firstName'] ?? '').toString(),
              'lastName': (userData?['lastName'] ?? lawyerData['lastName'] ?? '').toString(),
              'phone': (userData?['phone'] ?? lawyerData['phone'])?.toString(),
              'profilePicture': (userData?['profilePicture'] ?? lawyerData['profilePicture'])?.toString(),
              'lawyerProfile': hasProfile ? profileData : null,
            };
            
            // Debug: Print to see what we're getting
            if (userJson['firstName'] == '' && userJson['lastName'] == '') {
              print('Warning: Missing firstName/lastName for lawyer $userId');
              print('userData: $userData');
              print('lawyerData keys: ${lawyerData.keys.toList()}');
            }
            
            return UserModel.fromJson(userJson);
          } catch (e, stackTrace) {
            print('Error parsing lawyer data: $e');
            print('Stack trace: $stackTrace');
            print('Lawyer data: $lawyerData');
            rethrow;
          }
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getLawyerById(String lawyerId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.lawyers}/$lawyerId');

      if (response.data['success'] == true) {
        final lawyerData = response.data['data']['lawyer'];
        final userData = lawyerData['user'];
        
        return UserModel.fromJson({
          ...userData,
          'id': userData['_id'] ?? userData['id'] ?? '',
          'role': userData['role'] ?? 'LAWYER',
          'lawyerProfile': {
            'barLicenseNumber': lawyerData['barLicenseNumber'],
            'specialization': lawyerData['specialization'] ?? [],
            'experience': lawyerData['experience'] ?? 0,
            'hourlyRate': lawyerData['hourlyRate'] ?? 0,
            'bio': lawyerData['bio'],
            'rating': lawyerData['rating'] ?? 0.0,
            'totalReviews': lawyerData['totalReviews'] ?? 0,
            'isVerified': lawyerData['isVerified'] ?? false,
          },
        });
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.lawyers}/profile',
        data: profileData,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      rethrow;
    }
  }
}

