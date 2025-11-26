import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ConnectionTest {
  static Future<Map<String, dynamic>> testBackendConnection() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    try {
      print('🔍 Testing backend connection...');
      print('📍 URL: ${ApiConstants.baseUrl.replaceAll('/api', '')}/health');
      
      final response = await dio.get(
        '${ApiConstants.baseUrl.replaceAll('/api', '')}/health',
      );

      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
        'message': 'Backend is reachable',
      };
    } on DioException catch (e) {
      String message = 'Unknown error';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout - Backend may be spinning up (Render free tier takes 30-60s)';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Connection error - Backend may be down or unreachable';
      } else if (e.response != null) {
        message = 'HTTP ${e.response?.statusCode}: ${e.response?.data}';
      } else {
        message = e.message ?? 'Connection failed';
      }

      return {
        'success': false,
        'error': e.type.toString(),
        'message': message,
        'details': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: $e',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> testApiEndpoint(String endpoint) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    try {
      print('🔍 Testing API endpoint: $endpoint');
      final response = await dio.get(endpoint);
      
      return {
        'success': true,
        'statusCode': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.type.toString(),
        'message': e.message ?? 'Request failed',
        'statusCode': e.response?.statusCode,
      };
    }
  }
}

