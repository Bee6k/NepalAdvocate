import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _prefs = SharedPreferences.getInstance();

  // Secure storage methods
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<void> saveUserData(String userData) async {
    final prefs = await _prefs;
    await prefs.setString('user_data', userData);
  }

  Future<String?> getUserData() async {
    final prefs = await _prefs;
    return prefs.getString('user_data');
  }

  Future<void> saveRole(String role) async {
    final prefs = await _prefs;
    await prefs.setString('user_role', role);
  }

  Future<String?> getRole() async {
    final prefs = await _prefs;
    return prefs.getString('user_role');
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _prefs;
    await prefs.setBool('onboarding_completed', completed);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await _prefs;
    await prefs.clear();
  }
}

