import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class PostService {
  static const String _baseUrl =
      'https://twassol-api.madrasetna.net/twassolApi';

  // Static token for testing - same as ApiClient
  static const String _staticToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3NzA1NTU0OTMsImV4cCI6MTc3MDkwMTA5MywiaWF0IjoxNzcwNTU1NDkzfQ.y0Bofp8ubOD6-6cE0Pudi0TURooNIrvGe756Dm_mbjg';

  Future<String?> _getToken() async {
    // TODO: Uncomment when Azure AD is configured
    // final storage = FlutterSecureStorage();
    // return await storage.read(key: 'token');
    return _staticToken;
  }

  Future<PostResult> createPost({
    required String content,
    required String courseId,
    List<File>? files,
    String? spaceId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return PostResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      // Create multipart request
      final uri = Uri.parse('$_baseUrl/Post/Create');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['Content'] = content;
      request.fields['CourseId'] = courseId;

      if (spaceId != null && spaceId.isNotEmpty) {
        request.fields['SpaceId'] = spaceId;
      }

      // Add files
      if (files != null && files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final fileName = path.basename(file.path);
          final mimeType =
              lookupMimeType(file.path) ?? 'application/octet-stream';
          final mimeTypeParts = mimeType.split('/');

          final multipartFile = await http.MultipartFile.fromPath(
            'Files',
            file.path,
            filename: fileName,
            contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
          );
          request.files.add(multipartFile);
        }
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PostResult(success: true, message: 'تم انشاء المنشور بنجاح');
      } else if (response.statusCode == 403) {
        return PostResult(
          success: false,
          message: 'الادمن فقط من يستطيع النشر',
        );
      } else if (response.statusCode == 401) {
        return PostResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return PostResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PostResult(success: false, message: 'حدث خطأ في الاتصال: $e');
    }
  }

  /// Delete a post by ID
  Future<PostResult> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return PostResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse('$_baseUrl/Post/Delete/$postId');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return PostResult(success: true, message: 'تم حذف المنشور بنجاح');
      } else if (response.statusCode == 403) {
        return PostResult(success: false, message: 'غير مصرح بحذف هذا المنشور');
      } else if (response.statusCode == 401) {
        return PostResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else if (response.statusCode == 404) {
        return PostResult(success: false, message: 'المنشور غير موجود');
      } else {
        return PostResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PostResult(success: false, message: 'حدث خطأ في الاتصال: $e');
    }
  }
}

class PostResult {
  final bool success;
  final String message;

  PostResult({required this.success, required this.message});
}
