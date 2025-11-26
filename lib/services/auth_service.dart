import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/utils/api_client.dart';
import '../core/utils/storage_service.dart';
import '../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? phone,
    Map<String, dynamic>? lawyerData,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'email': email,
        'password': password,
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
        'acceptedTerms': acceptedTerms,
        'acceptedPrivacy': acceptedPrivacy,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };
      
      // Only include lawyerData if it has content (not empty)
      if (role == 'LAWYER' && lawyerData != null && lawyerData.isNotEmpty) {
        requestData['lawyerData'] = lawyerData;
      }
      
      final response = await _apiClient.post(
        ApiConstants.register,
        data: requestData,
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        await _storage.saveToken(authResponse.data!.token);
        await _storage.saveRole(authResponse.data!.user.role);
        await _storage.saveUserData(jsonEncode(authResponse.data!.user.toJson()));
      }

      return authResponse;
    } catch (e) {
      // Extract detailed error message from DioException
      if (e is DioException && e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          // Check for validation errors
          if (errorData.containsKey('errors') && errorData['errors'] is List) {
            final errors = errorData['errors'] as List;
            if (errors.isNotEmpty) {
              final errorMessages = errors
                  .map((err) => err is Map ? (err['msg'] ?? err.toString()) : err.toString())
                  .join(', ');
              throw Exception(errorMessages);
            }
          }
          // Check for general error message
          if (errorData.containsKey('message')) {
            throw Exception(errorData['message']);
          }
        }
      }
      rethrow;
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        await _storage.saveToken(authResponse.data!.token);
        await _storage.saveRole(authResponse.data!.user.role);
        await _storage.saveUserData(jsonEncode(authResponse.data!.user.toJson()));
        
        // Debug: Print user data to verify parsing
        print('Login successful - User: ${authResponse.data!.user.email}, Role: ${authResponse.data!.user.role}');
      } else {
        print('Login failed - Success: ${authResponse.success}, Message: ${authResponse.message}');
      }

      return authResponse;
    } catch (e) {
      // Provide better error messages for common issues
      if (e is DioException) {
        if (e.response?.statusCode == 502) {
          throw Exception('Backend service is not responding. Please wait 30-60 seconds and try again (Render free tier may be spinning up).');
        } else if (e.response?.statusCode == 503) {
          throw Exception('Backend service is temporarily unavailable. Please try again in a moment.');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Connection timeout. Backend may be spinning up. Please wait and try again.');
        }
      }
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Get current user timeout');
          throw Exception('Request timeout');
        },
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']['user']);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getStoredToken() async {
    return await _storage.getToken();
  }

  Future<String?> getStoredRole() async {
    return await _storage.getRole();
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.patch(
        ApiConstants.updateProfile,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final updatedUser = UserModel.fromJson(response.data['data']['user']);
        
        // Update stored user data
        await _storage.saveUserData(jsonEncode(updatedUser.toJson()));
        
        return updatedUser;
      }
      throw Exception(response.data['message'] ?? 'Failed to update profile');
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      rethrow;
    }
  }
}

