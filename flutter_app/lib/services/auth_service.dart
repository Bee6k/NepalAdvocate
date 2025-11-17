import 'dart:convert';
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
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'role': role,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          if (role == 'LAWYER' && lawyerData != null) 'lawyerData': lawyerData,
        },
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        await _storage.saveToken(authResponse.data!.token);
        await _storage.saveRole(authResponse.data!.user.role);
        await _storage.saveUserData(jsonEncode(authResponse.data!.user.toJson()));
      }

      return authResponse;
    } catch (e) {
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
      }

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      if (response.data['success'] == true && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']['user']);
      }
      return null;
    } catch (e) {
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
}

