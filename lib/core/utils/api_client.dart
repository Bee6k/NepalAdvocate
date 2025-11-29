import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();

  void initialize() {
    print('🔧 Initializing API Client...');
    print('📍 Base URL: ${ApiConstants.baseUrl}');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60), // Increased for Render free tier
        receiveTimeout: const Duration(seconds: 60), // Increased for Render free tier
        sendTimeout: const Duration(seconds: 60), // Increased for Render free tier
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('📤 API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 API Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.type}');
          print('   Path: ${error.requestOptions.path}');
          
          if (error.response != null) {
            final statusCode = error.response?.statusCode;
            print('   Status: $statusCode');
            
            // Handle 502 Bad Gateway (backend not responding)
            if (statusCode == 502) {
              print('   ⚠️ 502 Bad Gateway - Backend service is not responding');
              print('   💡 Possible causes:');
              print('      - Backend is spinning up (Render free tier takes 30-60s)');
              print('      - Backend crashed or failed to start');
              print('      - Check Render dashboard logs for errors');
              print('      - Verify MongoDB connection is working');
              print('   💡 Solution: Wait 30-60 seconds and try again');
            }
            // Handle 503 Service Unavailable
            else if (statusCode == 503) {
              print('   ⚠️ 503 Service Unavailable - Backend is temporarily unavailable');
              print('   💡 Backend may be restarting or spinning up');
            }
            // Handle 500 Internal Server Error
            else if (statusCode == 500) {
              print('   ⚠️ 500 Internal Server Error - Backend encountered an error');
              print('   💡 Check Render logs for detailed error messages');
            }
            // Handle 401 Unauthorized
            else if (statusCode == 401) {
              print('   🔐 Unauthorized - Token may be expired or invalid');
            }
            
            // Only print data if it's not HTML (502 errors return HTML error pages)
            final data = error.response?.data;
            if (data != null && data is! String) {
              print('   Data: $data');
            } else if (data is String && !data.contains('<!DOCTYPE html>')) {
              print('   Data: $data');
            }
          } else if (error.type == DioExceptionType.connectionTimeout) {
            print('   ⚠️ Connection timeout - Backend may be spinning up (Render free tier)');
            print('   💡 Wait 30-60 seconds and try again');
          } else if (error.type == DioExceptionType.connectionError) {
            print('   ⚠️ Connection error - Check if backend is running');
            print('   💡 Backend URL: ${ApiConstants.baseUrl}');
            print('   💡 Test: https://backend-vts8.onrender.com/health');
          }
          
          return handler.next(error);
        },
      ),
    );
    
    print('✅ API Client initialized');
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      rethrow;
    }
  }
}

