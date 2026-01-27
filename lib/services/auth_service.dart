import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/student_data.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'token');
    final logout = await _secureStorage.read(key: 'logout');
    return token != null && token.isNotEmpty && logout != 'true';
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  Future<StudentData?> getStudentData() async {
    final jsonString = await _secureStorage.read(key: 'StudentData');
    if (jsonString == null || jsonString.isEmpty) return null;
    return StudentData.fromJson(jsonDecode(jsonString));
  }

  Future<bool> logout() async {
    try {
      await _apiClient.post('Account/StudentLogout');
    } catch (e) {
      // Continue with local logout even if API fails
    }

    await _clearAllData();
    return true;
  }

  Future<void> _clearAllData() async {
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'id');
    await _secureStorage.delete(key: 'courseId');
    await _secureStorage.delete(key: 'userCountry');
    await _secureStorage.delete(key: 'StudentData');
    await _secureStorage.write(key: 'logout', value: 'true');
  }
}
