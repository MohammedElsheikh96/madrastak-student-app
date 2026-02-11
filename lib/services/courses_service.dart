import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/course.dart';
import '../models/curriculum.dart';
import '../models/task.dart';
import 'api_client.dart';

class CoursesService {
  final ApiClient _apiClient = ApiClient();

  // Base URL for courses API - using madrasetnaplus.eg
  static const String _coursesBaseUrl =
      'https://mfm-student.madrasetna.net/api';

  // Base URL for Tasks API - tm-plus
  static const String _tasksBaseUrl = 'https://tm-plus.madrasetna.net/api';

  // Static token for testing (public for external quiz access)
  static const String staticToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3NzA1NTU0OTMsImV4cCI6MTc3MDkwMTA5MywiaWF0IjoxNzcwNTU1NDkzfQ.y0Bofp8ubOD6-6cE0Pudi0TURooNIrvGe756Dm_mbjg';

  // Create HTTP client that bypasses SSL certificate verification (for development only)
  http.Client _createHttpClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Future<List<Course>> getBundleCourses() async {
    final response = await _apiClient.get('Bundles/GetBundleCoursesHesas');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['success'] == true && jsonData['returnObject'] != null) {
        final List<dynamic> coursesJson = jsonData['returnObject'];
        return coursesJson.map((json) => Course.fromJson(json)).toList();
      }

      return [];
    } else {
      throw Exception('Failed to load courses: ${response.statusCode}');
    }
  }

  /// Get course details by course ID
  Future<CourseDetails?> getCourseById(int courseId) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse(
        '$_coursesBaseUrl/Courses/getCourseById?id=$courseId',
      );

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return CourseDetails.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Get chapters with lessons for a course
  Future<ChaptersLessonsResponse?> getChaptersLessons(int courseId) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse(
        '$_coursesBaseUrl/Chapters/GetChaptersLessons?CourseId=$courseId',
      );
      debugPrint('CoursesService: getChaptersLessons URL: $uri');

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
      );
      debugPrint(
        'CoursesService: getChaptersLessons response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint(
          'CoursesService: getChaptersLessons chapters count: ${(jsonData['chapters'] as List?)?.length ?? 0}',
        );
        debugPrint(
          'CoursesService: getChaptersLessons quizzes count: ${(jsonData['quizzes'] as List?)?.length ?? 0}',
        );
        return ChaptersLessonsResponse.fromJson(jsonData);
      }
      debugPrint(
        'CoursesService: getChaptersLessons non-200: ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('CoursesService: getChaptersLessons error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Get tasks by day for a course with pagination
  Future<TasksByDayResponse?> getTasksByDay(
    String userId,
    int courseId, {
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse(
        '$_tasksBaseUrl/Tasks/GetNewTasksByDay?UserId=$userId&courseId=$courseId&PageNumber=$pageNumber&PageSize=$pageSize',
      );
      debugPrint('CoursesService: getTasksByDay URL: $uri');

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
      );
      debugPrint(
        'CoursesService: getTasksByDay response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint(
          'CoursesService: getTasksByDay success: ${jsonData['success']}',
        );
        return TasksByDayResponse.fromJson(jsonData);
      }
      debugPrint('CoursesService: getTasksByDay non-200: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('CoursesService: getTasksByDay error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Mark a task as completed (showMark flow)
  /// 1. Call AddTaskCompletion to create completion record
  /// 2. Call MarkTaskCompletionAsFinish to mark it as finished
  Future<bool> showMark({
    required String userId,
    required String taskId,
    required String? dueDate,
  }) async {
    final client = _createHttpClient();
    try {
      // Step 1: AddTaskCompletion
      final addCompletionUri = Uri.parse(
        '$_coursesBaseUrl/Tasks/AddTaskCompletion',
      );

      final model = {'DueDate': dueDate, 'taskId': taskId, 'userId': userId};

      debugPrint('CoursesService: AddTaskCompletion URL: $addCompletionUri');
      debugPrint('CoursesService: AddTaskCompletion body: $model');

      final addResponse = await client.post(
        addCompletionUri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(model),
      );

      debugPrint(
        'CoursesService: AddTaskCompletion response status: ${addResponse.statusCode}',
      );

      if (addResponse.statusCode != 200) {
        debugPrint(
          'CoursesService: AddTaskCompletion failed: ${addResponse.body}',
        );
        return false;
      }

      final addJsonData = jsonDecode(addResponse.body);
      debugPrint('CoursesService: AddTaskCompletion response: $addJsonData');

      final completionId = addJsonData['returnObject']?['id'];
      if (completionId == null) {
        debugPrint('CoursesService: No completion ID returned');
        return false;
      }

      // Step 2: MarkTaskCompletionAsFinish
      final markFinishUri = Uri.parse(
        '$_coursesBaseUrl/Tasks/MarkTaskCompletionAsFinish?id=$completionId',
      );

      debugPrint(
        'CoursesService: MarkTaskCompletionAsFinish URL: $markFinishUri',
      );

      final markResponse = await client.get(
        markFinishUri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'CoursesService: MarkTaskCompletionAsFinish response status: ${markResponse.statusCode}',
      );

      if (markResponse.statusCode == 200) {
        final markJsonData = jsonDecode(markResponse.body);
        debugPrint(
          'CoursesService: MarkTaskCompletionAsFinish response: $markJsonData',
        );
        return true;
      }

      debugPrint(
        'CoursesService: MarkTaskCompletionAsFinish failed: ${markResponse.body}',
      );
      return false;
    } catch (e) {
      debugPrint('CoursesService: showMark error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  /// Change lesson status
  /// lessonStatus: 1 = started, 2 = completed
  Future<bool> changeLessonStatus({
    required int lessonId,
    required int lessonStatus,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse(
        '$_coursesBaseUrl/Lessons/ChangeLessonStatus/$lessonId/$lessonStatus',
      );

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📤 changeLessonStatus REQUEST:');
      debugPrint('   URL: $uri');
      debugPrint('   Method: GET');
      debugPrint('   lessonId: $lessonId');
      debugPrint('   lessonStatus: $lessonStatus');
      debugPrint('═══════════════════════════════════════════════════════');

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📥 changeLessonStatus RESPONSE:');
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');
      debugPrint('═══════════════════════════════════════════════════════');

      if (response.statusCode == 200) {
        debugPrint('✅ changeLessonStatus SUCCESS');
        return true;
      }

      debugPrint('❌ changeLessonStatus FAILED');
      return false;
    } catch (e) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ changeLessonStatus ERROR: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    } finally {
      client.close();
    }
  }

  /// Change lesson video progress (S3 Video)
  /// URL format: /Lessons/ChangeS3VideoProgress/{enrollmentId}/{courseId}/{lessonId}/{currentTime}/{duration}
  Future<bool> changeS3VideoProgress({
    required String enrollmentId,
    required int courseId,
    required int lessonId,
    required double currentTime,
    required double duration,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse(
        '$_coursesBaseUrl/Lessons/ChangeS3VideoProgress/$enrollmentId/$courseId/$lessonId/$currentTime/$duration',
      );

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📤 changeS3VideoProgress REQUEST:');
      debugPrint('   URL: $uri');
      debugPrint('   Method: GET');
      debugPrint('   enrollmentId: $enrollmentId');
      debugPrint('   courseId: $courseId');
      debugPrint('   lessonId: $lessonId');
      debugPrint('   currentTime: $currentTime');
      debugPrint('   duration: $duration');
      debugPrint('═══════════════════════════════════════════════════════');

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $staticToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📥 changeS3VideoProgress RESPONSE:');
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');
      debugPrint('═══════════════════════════════════════════════════════');

      if (response.statusCode == 200) {
        debugPrint('✅ changeS3VideoProgress SUCCESS');
        return true;
      }

      debugPrint('❌ changeS3VideoProgress FAILED');
      return false;
    } catch (e) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ changeS3VideoProgress ERROR: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    } finally {
      client.close();
    }
  }

  // AWS S3 credentials for PDF signing (from environment.awsCred)
  // TODO: Move these to environment variables or secure storage
  static const String _awsAccessKey = String.fromEnvironment(
    'AWS_ACCESS_KEY',
    defaultValue: '',
  );
  static const String _awsSecretKey = String.fromEnvironment(
    'AWS_SECRET_KEY',
    defaultValue: '',
  );
  static const String _awsRegion = 'eu-central-1';
  static const String _awsBucket = 'madrstna-plus-bucket-v2';

  /// Get signed URL for PDF from AWS S3 using Signature Version 2
  /// This matches the AWS SDK's S3.getSignedUrl method used in Angular
  /// [key] is the content path from lesson.content
  String getSignedPdfUrl(String key) {
    debugPrint('CoursesService: getSignedPdfUrl input key: $key');

    // Clean the key - remove leading slash if present
    String cleanKey = key;
    if (cleanKey.startsWith('/')) {
      cleanKey = cleanKey.substring(1);
    }
    debugPrint('CoursesService: cleaned key: $cleanKey');

    // Expires: Unix timestamp (seconds since epoch) + 3 hours
    final expires =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 10800;
    debugPrint('CoursesService: expires timestamp: $expires');

    // String to sign format for AWS Signature Version 2 (Query String Auth)
    // The key in the signature should NOT be URL-encoded
    // Format: HTTP-VERB + "\n" + Content-MD5 + "\n" + Content-Type + "\n" + Expires + "\n" + CanonicalizedAmzHeaders + CanonicalizedResource
    final stringToSign = 'GET\n\n\n$expires\n/$_awsBucket/$cleanKey';
    debugPrint('CoursesService: stringToSign:\n$stringToSign');

    // Create HMAC-SHA1 signature
    final hmac = crypto.Hmac(crypto.sha1, utf8.encode(_awsSecretKey));
    final digest = hmac.convert(utf8.encode(stringToSign));
    final signature = base64.encode(digest.bytes);
    debugPrint('CoursesService: signature (base64): $signature');

    // URL encode the signature
    final encodedSignature = Uri.encodeComponent(signature);
    debugPrint('CoursesService: encodedSignature: $encodedSignature');

    // URL encode each part of the key path (but not the slashes)
    final encodedKey = cleanKey
        .split('/')
        .map((part) => Uri.encodeComponent(part))
        .join('/');
    debugPrint('CoursesService: encodedKey: $encodedKey');

    // Build the S3 URL using virtual-hosted style (bucket.s3.region.amazonaws.com)
    final signedUrl =
        'https://$_awsBucket.s3.$_awsRegion.amazonaws.com/$encodedKey'
        '?AWSAccessKeyId=$_awsAccessKey'
        '&Expires=$expires'
        '&Signature=$encodedSignature';

    debugPrint('CoursesService: Generated signed PDF URL: $signedUrl');
    return signedUrl;
  }
}
