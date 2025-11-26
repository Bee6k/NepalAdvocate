import 'dart:io';
import 'package:dio/dio.dart';
import '../core/utils/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Upload profile picture
  Future<UserModel> uploadProfilePicture(File imageFile) async {
    try {
      final response = await _apiClient.uploadFile(
        ApiConstants.uploadProfilePicture,
        imageFile.path,
        fieldName: 'image',
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']['user']);
      }
      throw Exception(response.data['message'] ?? 'Failed to upload profile picture');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete profile picture
  Future<UserModel> deleteProfilePicture() async {
    try {
      final response = await _apiClient.delete(
        ApiConstants.deleteProfilePicture,
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']['user']);
      }
      throw Exception(response.data['message'] ?? 'Failed to delete profile picture');
    } catch (e) {
      rethrow;
    }
  }
}

