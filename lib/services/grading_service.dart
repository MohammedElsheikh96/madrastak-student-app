import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/grade_book_result.dart';

class GradingService {
  static const String _baseUrl = 'https://mfm-student.madrasetna.net/api';

  // Static student ID for testing
  static const String _staticStudentId =
      'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';

  // Static token for testing
  static const String _staticToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3NzIzNzE0NjksImV4cCI6MTc3MjcxNzA2OSwiaWF0IjoxNzcyMzcxNDY5fQ.1MdmPe2r0kAiYluc9l1aZ1SIXjbHbUoruji4q89nqzM';

  http.Client _createHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<GradeBookResult?> getGradeBookResult(String courseId) async {
    final client = _createHttpClient();
    try {
      final url = '$_baseUrl/Grading/getGradeBookResult';
      final bodyList = [
        {
          'courseId': int.tryParse(courseId) ?? courseId,
          'studentId': _staticStudentId,
        }
      ];
      debugPrint('=== GRADING API CALL ===');
      debugPrint('URL: $url');
      debugPrint('Body: $bodyList');

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_staticToken',
        },
        body: jsonEncode(bodyList),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body (first 500): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('Parsed keys: ${data.keys.toList()}');
      debugPrint('status value: ${data['status']} (type: ${data['status'].runtimeType})');
      debugPrint('returnObject is null: ${data['returnObject'] == null}');

      if (data['status'] == true && data['returnObject'] != null) {
        final returnObject = data['returnObject'];
        debugPrint('returnObject type: ${returnObject.runtimeType}');

        if (returnObject is List) {
          debugPrint('returnObject length: ${returnObject.length}');
          if (returnObject.isNotEmpty) {
            final firstResult = returnObject[0] as Map<String, dynamic>;
            debugPrint('firstResult keys: ${firstResult.keys.toList()}');
            if (firstResult['result'] != null) {
              final result = GradeBookResult.fromJson(
                  firstResult['result'] as Map<String, dynamic>);
              debugPrint('Parsed GradeBookResult: ${result.categoryResults.length} categories, total: ${result.totalPercentage}');
              return result;
            } else {
              debugPrint('firstResult["result"] is NULL');
            }
          }
        } else if (returnObject is Map) {
          debugPrint('returnObject is a Map with keys: ${returnObject.keys.toList()}');
        }
      } else {
        debugPrint('STATUS CHECK FAILED: status=${data['status']}, returnObject null=${data['returnObject'] == null}');
      }

      debugPrint('Returning empty GradeBookResult');
      return GradeBookResult(categoryResults: [], totalPercentage: 0.0);
    } catch (e, stackTrace) {
      debugPrint('ERROR fetching grade book: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    } finally {
      client.close();
    }
  }
}
