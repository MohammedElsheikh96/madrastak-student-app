import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class UserService {
  static const String _baseUrl =
      'https://twassol-api.madrasetna.net/twassolApi';

  static const String _staticToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3NzIzNzE0NjksImV4cCI6MTc3MjcxNzA2OSwiaWF0IjoxNzcyMzcxNDY5fQ.1MdmPe2r0kAiYluc9l1aZ1SIXjbHbUoruji4q89nqzM';

  Future<String?> _getToken() async {
    return _staticToken;
  }

  /// Update user profile: Name, Biography, and optionally ProfileImage (binary)
  /// All sent to User/Update as multipart form-data
  Future<UserUpdateResult> updateProfile({
    String? name,
    String? biography,
    File? profileImage,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return UserUpdateResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse('$_baseUrl/User/Update');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (name != null) request.fields['Name'] = name;
      if (biography != null) request.fields['Biography'] = biography;

      if (profileImage != null) {
        final fileName = profileImage.path.split('/').last.split('\\').last;
        final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';
        final mimeTypeParts = mimeType.split('/');

        final multipartFile = await http.MultipartFile.fromPath(
          'ProfileImage',
          profileImage.path,
          filename: fileName,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserUpdateResult(
          success: true,
          message: 'تم تحديث الملف الشخصي بنجاح',
        );
      } else if (response.statusCode == 401) {
        return UserUpdateResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return UserUpdateResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UserUpdateResult(
        success: false,
        message: 'حدث خطأ في الاتصال: $e',
      );
    }
  }

  /// Update cover image (separate API)
  Future<UserUpdateResult> updateCoverImage(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return UserUpdateResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse('$_baseUrl/User/UpdateCoverImage');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final fileName = imageFile.path.split('/').last.split('\\').last;
      final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');

      final multipartFile = await http.MultipartFile.fromPath(
        'CoverImage',
        imageFile.path,
        filename: fileName,
        contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String? imageUrl;
        try {
          final data = jsonDecode(response.body);
          imageUrl = data['imageUrl'] ?? data['coverImageUrl'] ?? data['url'];
        } catch (_) {}

        return UserUpdateResult(
          success: true,
          message: 'تم تحديث صورة الغلاف بنجاح',
          imageUrl: imageUrl,
        );
      } else if (response.statusCode == 401) {
        return UserUpdateResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return UserUpdateResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UserUpdateResult(
        success: false,
        message: 'حدث خطأ في الاتصال: $e',
      );
    }
  }
}

class UserUpdateResult {
  final bool success;
  final String message;
  final String? imageUrl;

  UserUpdateResult({
    required this.success,
    required this.message,
    this.imageUrl,
  });
}
