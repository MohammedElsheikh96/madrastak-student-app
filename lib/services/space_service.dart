import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/post.dart';

class SpaceService {
  static const String _baseUrl =
      'https://twassol-api.madrasetna.net/twassolApi';

  // Static token for testing - same as ApiClient
  static const String _staticToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjJiODVmZTk2LTU3ZjgtNDBiNi05NjAxLTMyYTA3Mjg4NmUxMSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvdXNlcmRhdGEiOiJjNTA2MTY3My01YjVmLTRlNWUtYWI3OC1kOWY1MWVlZjNkZDIiLCJuYW1lIjoi2LnYqNiv2KfZhNmH2KfYr9mJINmF2K3ZhdivINi52KjYr9in2YTZh9in2K_ZiSDYudmE2Ykg2KfZhNi02YrZiNmJIiwiZW1haWwiOiIxNDU0MUBzYWJyb2FkLm1vZS5lZHUuZWciLCJwaG9uZV9udW1iZXIiOiIiLCJwcm9maWxlX3BpY3R1cmVfdXJsIjoiIiwic3RhZ2VfbmFtZSI6Itin2YTYqti52YTZitmFINin2YTYp9i52K_Yp9iv2YogIiwiZ3JhZGVfbmFtZSI6Itin2YTYtdmBINin2YTYq9in2YbZiiDYp9mE2KfYudiv2KfYr9mKIiwiY291bnRyeV9uYW1lIjoi2KXZiti32KfZhNmK2KciLCJuYmYiOjE3Njk1MTQ3MTEsImV4cCI6MTc2OTg2MDMxMSwiaWF0IjoxNzY5NTE0NzExfQ.uLbi6Ih3MsUq-Hyastmj2HP7IPpw9EgGz01gvsi3NiY';

  Future<String?> _getToken() async {
    return _staticToken;
  }

  /// Get course spaces for a given external course ID
  /// Returns SpaceResult with space data if found
  Future<SpaceResult> getCourseSpaces(int courseId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return SpaceResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse(
        '$_baseUrl/Course/GetCourseSpaces?ExternalCourseId=$courseId',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if space exists in the response
        if (data != null &&
            data['space'] != null &&
            data['space']['id'] != null) {
          return SpaceResult(
            success: true,
            message: 'تم العثور على المساحة',
            space: Space.fromJson(data['space']),
          );
        } else {
          // Space not found
          return SpaceResult(
            success: true,
            message: 'لم يتم العثور على مساحة',
            space: null,
          );
        }
      } else if (response.statusCode == 401) {
        return SpaceResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return SpaceResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SpaceResult(success: false, message: 'حدث خطأ في الاتصال: $e');
    }
  }

  /// Create a new space for a course
  /// Returns SpaceResult with the new spaceId
  Future<SpaceResult> createDigitalSchoolCourseSpace(
    int externalCourseId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return SpaceResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse('$_baseUrl/Space/CreateDigitalSchoolCourseSpace');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'externalCourseId': externalCourseId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data != null && data['spaceId'] != null) {
          return SpaceResult(
            success: true,
            message: 'تم إنشاء المساحة بنجاح',
            spaceId: data['spaceId'].toString(),
          );
        } else {
          return SpaceResult(
            success: false,
            message: 'لم يتم إرجاع معرف المساحة',
          );
        }
      } else if (response.statusCode == 401) {
        return SpaceResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return SpaceResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SpaceResult(success: false, message: 'حدث خطأ في الاتصال: $e');
    }
  }

  /// Get single post by ID with full details including comments
  /// Returns PostDetailResult with post and comments data
  Future<PostDetailResult> getPostById(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return PostDetailResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse('$_baseUrl/Post/GetById?postId=$postId');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('GetById Response status: ${response.statusCode}');
      print('GetById Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // API may return data directly or wrapped in 'data' field
        Map<String, dynamic>? postData;
        if (responseData != null) {
          if (responseData['data'] != null) {
            postData = responseData['data'];
          } else if (responseData['id'] != null) {
            // Data returned directly without wrapper
            postData = responseData;
          }
        }

        if (postData != null) {
          final postDetail = PostDetail.fromJson(postData);
          return PostDetailResult(
            success: true,
            message: 'تم تحميل المنشور بنجاح',
            postDetail: postDetail,
          );
        } else {
          return PostDetailResult(
            success: false,
            message: 'لم يتم العثور على المنشور',
          );
        }
      } else if (response.statusCode == 401) {
        return PostDetailResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return PostDetailResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PostDetailResult(
        success: false,
        message: 'حدث خطأ في الاتصال: $e',
      );
    }
  }

  /// Get all posts for a space with pagination
  /// Returns PostsResult with posts data
  Future<PostsResult> getPostsPaged({
    required String spaceId,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return PostsResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse(
        '$_baseUrl/Post/GetAllPaged?SpaceId=$spaceId&PageNumber=$pageNumber&PageSize=$pageSize',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['data'] != null) {
          final pagedResponse = PostsPagedResponse.fromJson(data['data']);
          return PostsResult(
            success: true,
            message: 'تم تحميل المنشورات بنجاح',
            posts: pagedResponse.posts,
            totalCount: pagedResponse.totalCount,
          );
        } else {
          return PostsResult(
            success: true,
            message: 'لا توجد منشورات',
            posts: [],
            totalCount: 0,
          );
        }
      } else if (response.statusCode == 401) {
        return PostsResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return PostsResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PostsResult(success: false, message: 'حدث خطأ في الاتصال: $e');
    }
  }

  /// Like a post
  /// entityType: 1 for posts
  /// Returns true on success, false on failure
  Future<bool> likePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final uri = Uri.parse('$_baseUrl/Like/CreateLike');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'entityType': 1, 'entityID': postId}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Unlike a post
  /// entityType: 1 for posts
  /// Returns true on success, false on failure
  Future<bool> unlikePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final uri = Uri.parse(
        '$_baseUrl/Like/Unlike?entityType=1&EntityID=$postId',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Like a comment
  /// entityType: 2 for comments
  /// Returns true on success, false on failure
  Future<bool> likeComment(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final uri = Uri.parse('$_baseUrl/Like/CreateLike');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'entityType': 2, 'entityID': commentId}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Unlike a comment
  /// entityType: 2 for comments
  /// Returns true on success, false on failure
  Future<bool> unlikeComment(String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final uri = Uri.parse(
        '$_baseUrl/Like/Unlike?entityType=2&EntityID=$commentId',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Create a comment or reply
  /// If parentCommentId is null, it's a root comment
  /// If parentCommentId is provided, it's a reply to that comment
  Future<CreateCommentResult> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return CreateCommentResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      final uri = Uri.parse('$_baseUrl/Comment/Create');

      final body = {'postId': postId, 'content': content};

      if (parentCommentId != null) {
        body['parentCommentId'] = parentCommentId;
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Parse the created comment from response
        Map<String, dynamic>? commentData;
        if (data != null) {
          if (data['data'] != null) {
            commentData = data['data'];
          } else if (data['id'] != null) {
            commentData = data;
          }
        }

        if (commentData != null) {
          return CreateCommentResult(
            success: true,
            message: 'تم إضافة التعليق بنجاح',
            comment: PostComment.fromJson(commentData),
          );
        }

        return CreateCommentResult(
          success: true,
          message: 'تم إضافة التعليق بنجاح',
        );
      } else if (response.statusCode == 401) {
        return CreateCommentResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else {
        return CreateCommentResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return CreateCommentResult(
        success: false,
        message: 'حدث خطأ في الاتصال: $e',
      );
    }
  }

  /// Create a new post with optional files
  /// Uses multipart/form-data to upload files
  Future<CreatePostResult> createPost({
    required String content,
    String? spaceId,
    List<File>? files,
    int privacy = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return CreatePostResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول',
        );
      }

      // Content must be at least 10 characters (matching Angular validation)
      if (content.length < 10 && (files == null || files.isEmpty)) {
        return CreatePostResult(
          success: false,
          message: 'يجب كتابة محتوى المنشور (10 أحرف على الأقل)',
        );
      }

      final uri = Uri.parse('$_baseUrl/Post/Create');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['Content'] = content;
      request.fields['Configuration.Privacy'] = privacy.toString();

      // Add SpaceId if provided
      if (spaceId != null && spaceId.isNotEmpty) {
        request.fields['SpaceId'] = spaceId;
      }

      // Add files if provided
      if (files != null && files.isNotEmpty) {
        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          final fileName = file.path.split('/').last.split('\\').last;

          // Determine MIME type
          final mimeType =
              lookupMimeType(fileName) ?? 'application/octet-stream';
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

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreatePostResult(
          success: true,
          message: 'تم انشاء المنشور بنجاح',
        );
      } else if (response.statusCode == 401) {
        return CreatePostResult(
          success: false,
          message: 'غير مصرح - يرجى تسجيل الدخول مرة أخرى',
        );
      } else if (response.statusCode == 403) {
        return CreatePostResult(
          success: false,
          message: 'الادمن فقط من يستطيع النشر',
        );
      } else {
        return CreatePostResult(
          success: false,
          message: 'حدث خطأ: ${response.statusCode}',
        );
      }
    } catch (e) {
      return CreatePostResult(
        success: false,
        message: 'حدث خطأ في الاتصال: $e',
      );
    }
  }
}

class CreatePostResult {
  final bool success;
  final String message;

  CreatePostResult({required this.success, required this.message});
}

class CreateCommentResult {
  final bool success;
  final String message;
  final PostComment? comment;

  CreateCommentResult({
    required this.success,
    required this.message,
    this.comment,
  });
}

class PostsResult {
  final bool success;
  final String message;
  final List<Post>? posts;
  final int totalCount;

  PostsResult({
    required this.success,
    required this.message,
    this.posts,
    this.totalCount = 0,
  });
}

class PostDetailResult {
  final bool success;
  final String message;
  final PostDetail? postDetail;

  PostDetailResult({
    required this.success,
    required this.message,
    this.postDetail,
  });
}

class SpaceResult {
  final bool success;
  final String message;
  final Space? space;
  final String? spaceId;

  SpaceResult({
    required this.success,
    required this.message,
    this.space,
    this.spaceId,
  });
}

class Space {
  final String id;
  final String? name;
  final String? description;
  final int? externalCourseId;

  Space({required this.id, this.name, this.description, this.externalCourseId});

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id']?.toString() ?? '',
      name: json['name'],
      description: json['description'],
      externalCourseId: json['externalCourseId'],
    );
  }
}
