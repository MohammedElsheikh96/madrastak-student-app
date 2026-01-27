import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/azure_ad_config.dart';
import '../models/azure_ad_login_response.dart';
import '../models/student_data.dart';
import '../models/api_exception.dart';

class AzureADService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _storedNonce;

  /// Builds the Microsoft Azure AD authorization URL
  String buildAuthorizationUrl({String? returnUrl}) {
    final nonce = _generateNonce();
    _storedNonce = nonce;
    final state = returnUrl ?? '/';

    final params = {
      'client_id': AzureADConfig.clientId,
      'response_type': 'id_token token',
      'redirect_uri': AzureADConfig.redirectUri,
      'response_mode': 'fragment',
      'scope': AzureADConfig.scopes.join(' '),
      'state': state,
      'nonce': nonce,
      'prompt': 'select_account',
    };

    final queryString = Uri(queryParameters: params).query;
    return '${AzureADConfig.authority}/oauth2/v2.0/authorize?$queryString';
  }

  /// Generates a random nonce for security
  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Parses the URL fragment from the callback
  Map<String, String> _parseFragment(String fragment) {
    final params = <String, String>{};

    // Remove leading '#' if present
    final cleanFragment = fragment.startsWith('#') ? fragment.substring(1) : fragment;

    final pairs = cleanFragment.split('&');
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        params[parts[0]] = Uri.decodeComponent(parts[1]);
      }
    }
    return params;
  }

  /// Handles the Azure AD callback by parsing tokens and sending to backend
  Future<AzureADLoginResponse> handleCallback(String callbackUrl) async {
    // Parse the callback URL
    final uri = Uri.parse(callbackUrl);
    final fragment = uri.fragment;

    if (fragment.isEmpty) {
      throw ApiException(
        success: false,
        statusCode: '400',
        message: 'No response received from Azure AD',
      );
    }

    final params = _parseFragment(fragment);

    final accessToken = params['access_token'];
    final idToken = params['id_token'];
    final state = params['state'];
    final error = params['error'];
    final errorDescription = params['error_description'];

    // Check for errors from Azure AD
    if (error != null) {
      throw ApiException(
        success: false,
        statusCode: '401',
        message: errorDescription ?? error,
      );
    }

    if (accessToken == null || idToken == null) {
      throw ApiException(
        success: false,
        statusCode: '400',
        message: 'Missing tokens in Azure AD response',
      );
    }

    // Send tokens to backend API for validation and user creation/login
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/azure-ad/callback'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'accessToken': accessToken,
        'idToken': idToken,
        'state': state,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return AzureADLoginResponse.fromJson(jsonData);
    } else if (response.statusCode == 403) {
      // Country restriction error
      final errorData = jsonDecode(response.body);
      throw ApiException(
        success: errorData['success'] ?? false,
        statusCode: '403',
        message: errorData['message'] ?? 'Country not supported',
      );
    } else {
      final errorData = jsonDecode(response.body);
      throw ApiException(
        success: false,
        statusCode: response.statusCode.toString(),
        message: errorData['message'] ?? 'Failed to authenticate with backend',
      );
    }
  }

  /// Stores authentication data from Azure AD login response
  /// This format MUST match the regular login (CheckVerificationCode) storage format
  Future<void> storeAuthData(AzureADLoginResponse loginResponse) async {
    // Store individual tokens and IDs
    await _secureStorage.write(key: 'token', value: loginResponse.token);
    await _secureStorage.write(key: 'id', value: loginResponse.id);
    await _secureStorage.write(
        key: 'courseId', value: loginResponse.courseId.toString());
    await _secureStorage.write(
        key: 'userCountry', value: loginResponse.countryName);

    // Create StudentData object in the same format as regular login
    final studentData = StudentData(
      token: loginResponse.token,
      id: loginResponse.id,
      userBasicInfo: loginResponse.userBasicInfo,
      accountPreference: loginResponse.accountPreference,
      onBoardingStatus: loginResponse.onBoardingStatus,
      language: loginResponse.language,
      gender: loginResponse.gender,
      weight: loginResponse.weight,
      height: loginResponse.height,
      countryName: loginResponse.countryName,
    );

    // Store StudentData as JSON string
    await _secureStorage.write(
      key: 'StudentData',
      value: jsonEncode(studentData.toJson()),
    );

    // Set logout flag to false
    await _secureStorage.write(key: 'logout', value: 'false');

    // Debug: Log stored data (remove in production)
    if (kDebugMode) {
      debugPrint('Azure AD - Stored auth data:');
      debugPrint('  token: ${loginResponse.token.substring(0, min(20, loginResponse.token.length))}...');
      debugPrint('  id: ${loginResponse.id}');
      debugPrint('  courseId: ${loginResponse.courseId}');
      debugPrint('  countryName: ${loginResponse.countryName}');
    }
  }

  /// Retrieves stored StudentData
  Future<StudentData?> getStoredStudentData() async {
    final jsonString = await _secureStorage.read(key: 'StudentData');
    if (jsonString == null) return null;

    return StudentData.fromJson(jsonDecode(jsonString));
  }

  /// Retrieves stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  /// Retrieves stored courseId
  Future<String?> getCourseId() async {
    return await _secureStorage.read(key: 'courseId');
  }

  /// Checks if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final logout = await _secureStorage.read(key: 'logout');
    return token != null && logout != 'true';
  }

  /// Clears all stored auth data (for logout)
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'token');
    await _secureStorage.delete(key: 'id');
    await _secureStorage.delete(key: 'courseId');
    await _secureStorage.delete(key: 'userCountry');
    await _secureStorage.delete(key: 'StudentData');
    await _secureStorage.write(key: 'logout', value: 'true');
  }
}
