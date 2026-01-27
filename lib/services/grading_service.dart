import 'dart:convert';
import '../models/grade_book_result.dart';
import 'api_client.dart';

class GradingService {
  final ApiClient _apiClient = ApiClient();

  // Static student ID for testing
  static const String _staticStudentId = 'c5061673-5b5f-4e5e-ab78-d9f51eef3dd2';

  Future<GradeBookResult?> getGradeBookResult(String courseId) async {
    try {
      final response = await _apiClient.post(
        'Grading/getGradeBookResult',
        body: {
          'courseId': courseId,
          'studentId': _staticStudentId,
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == true && data['returnObject'] != null) {
        final returnObject = data['returnObject'] as List<dynamic>;
        if (returnObject.isNotEmpty) {
          final firstResult = returnObject[0] as Map<String, dynamic>;
          if (firstResult['result'] != null) {
            return GradeBookResult.fromJson(
                firstResult['result'] as Map<String, dynamic>);
          }
        }
      }
      return GradeBookResult(categoryResults: [], totalPercentage: 0.0);
    } catch (e) {
      debugPrint('Error fetching grade book result: $e');
      return null;
    }
  }
}

void debugPrint(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}
