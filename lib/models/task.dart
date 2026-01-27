import 'package:flutter/material.dart';

/// Task details for Learning Object type (referenceType 3)
class TaskDetailsLO {
  final int id;
  final String name;
  final String? arabicName;
  final String? shortDescription;
  final String? arabicShortDescription;
  final String? image;
  final String? imageAr;
  final String? portraitImage;
  final String? portraitImageAr;
  final int type; // 4 = video
  final String? content;
  final int? lessonId;
  final String? lessonName;
  final String? lessonArabicName;

  TaskDetailsLO({
    required this.id,
    required this.name,
    this.arabicName,
    this.shortDescription,
    this.arabicShortDescription,
    this.image,
    this.imageAr,
    this.portraitImage,
    this.portraitImageAr,
    required this.type,
    this.content,
    this.lessonId,
    this.lessonName,
    this.lessonArabicName,
  });

  factory TaskDetailsLO.fromJson(Map<String, dynamic> json) {
    final lesson = json['lesson'] as Map<String, dynamic>?;
    return TaskDetailsLO(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      shortDescription: json['shortDescription'] as String?,
      arabicShortDescription: json['arabicShortDescription'] as String?,
      image: json['image'] as String?,
      imageAr: json['imageAr'] as String?,
      portraitImage: json['portraitImage'] as String?,
      portraitImageAr: json['portraitImageAr'] as String?,
      type: json['type'] as int? ?? 0,
      content: json['content'] as String?,
      lessonId: json['lessonId'] as int?,
      lessonName: lesson?['name'] as String?,
      lessonArabicName: lesson?['arabicName'] as String?,
    );
  }

  String get displayName => arabicName ?? name;
  String get displayImage => portraitImage ?? image ?? '';
  String get displayLessonName => lessonArabicName ?? lessonName ?? '';
}

/// Task details for Quiz type (referenceType 1)
class TaskDetailsQuiz {
  final String id;
  final String name;
  final int? interestId;
  final int? subInterestId;
  final String? url;
  final int? courseId;
  final int? chapterId;
  final int? lessonId;
  final int? learningObjectId;
  final String? landscapeImage;
  final String? portraitImage;

  TaskDetailsQuiz({
    required this.id,
    required this.name,
    this.interestId,
    this.subInterestId,
    this.url,
    this.courseId,
    this.chapterId,
    this.lessonId,
    this.learningObjectId,
    this.landscapeImage,
    this.portraitImage,
  });

  factory TaskDetailsQuiz.fromJson(Map<String, dynamic> json) {
    return TaskDetailsQuiz(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      interestId: json['interestId'] as int?,
      subInterestId: json['subInterestId'] as int?,
      url: json['url'] as String?,
      courseId: json['courseId'] as int?,
      chapterId: json['chapterId'] as int?,
      lessonId: json['lessonId'] as int?,
      learningObjectId: json['learningObjectId'] as int?,
      landscapeImage: json['landscapeImage'] as String?,
      portraitImage: json['portraitImage'] as String?,
    );
  }

  String get displayImage => portraitImage ?? landscapeImage ?? '';
}

/// Task details for Discussion type (referenceType 5)
class TaskDetailsDiscussion {
  final String id;
  final String? title;
  final String? content;
  final String? description;
  final int viewCount;
  final int commentsCount;
  final int likesCount;
  final bool isLikedByMe;
  final List<TaskFile> files;
  final TaskUser? user;

  TaskDetailsDiscussion({
    required this.id,
    this.title,
    this.content,
    this.description,
    required this.viewCount,
    required this.commentsCount,
    required this.likesCount,
    required this.isLikedByMe,
    required this.files,
    this.user,
  });

  factory TaskDetailsDiscussion.fromJson(Map<String, dynamic> json) {
    return TaskDetailsDiscussion(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String?,
      description: json['description'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      likesCount: json['likesCount'] as int? ?? 0,
      isLikedByMe: json['islikedByMe'] as bool? ?? false,
      files: (json['files'] as List<dynamic>?)
              ?.map((f) => TaskFile.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      user: json['user'] != null
          ? TaskUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  String? get firstImageUrl =>
      files.isNotEmpty ? files.first.path : null;
}

class TaskFile {
  final String name;
  final String type;
  final double size;
  final String path;
  final String? externalId;

  TaskFile({
    required this.name,
    required this.type,
    required this.size,
    required this.path,
    this.externalId,
  });

  factory TaskFile.fromJson(Map<String, dynamic> json) {
    return TaskFile(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      size: (json['size'] as num?)?.toDouble() ?? 0,
      path: json['path'] as String? ?? '',
      externalId: json['externalId'] as String?,
    );
  }
}

class TaskUser {
  final String id;
  final String? profileImageUrl;
  final String? name;

  TaskUser({
    required this.id,
    this.profileImageUrl,
    this.name,
  });

  factory TaskUser.fromJson(Map<String, dynamic> json) {
    return TaskUser(
      id: json['id'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      name: json['name'] as String?,
    );
  }
}

/// Main Task model for course tasks
class Task {
  final int taskId;
  final String taskName;
  final int referenceType; // 1,2 = تدريب/واجب (purple), 3 = شرح (orange), 5 = نقاش (blue)
  final String referenceTypeName;
  final String? referenceTypeNameAr;
  final String referenceId;
  final String? description;
  final String? startDate;
  final String? dueDate;
  final int toDoListOrder;
  final bool isShared;
  final bool isOpened; // true = completed (show green checkmark)
  final String? openDate;
  final bool? isCompleted;
  final String? completionDate;
  final List<String> tags;
  final int courseId;
  final String? courseName;
  final String? courseArabicName;
  final String? courseImage;

  // Task details - one of these will be populated based on referenceType
  final TaskDetailsLO? taskDetailsLO;
  final TaskDetailsQuiz? taskDetailsQuiz;
  final TaskDetailsDiscussion? taskDetailsDiscussion;

  Task({
    required this.taskId,
    required this.taskName,
    required this.referenceType,
    required this.referenceTypeName,
    this.referenceTypeNameAr,
    required this.referenceId,
    this.description,
    this.startDate,
    this.dueDate,
    required this.toDoListOrder,
    required this.isShared,
    required this.isOpened,
    this.openDate,
    this.isCompleted,
    this.completionDate,
    required this.tags,
    required this.courseId,
    this.courseName,
    this.courseArabicName,
    this.courseImage,
    this.taskDetailsLO,
    this.taskDetailsQuiz,
    this.taskDetailsDiscussion,
  });

  factory Task.fromJson(Map<String, dynamic> json, int refType) {
    final course = json['course'] as Map<String, dynamic>?;
    final taskDetails = json['taskDetails'] as Map<String, dynamic>?;

    TaskDetailsLO? detailsLO;
    TaskDetailsQuiz? detailsQuiz;
    TaskDetailsDiscussion? detailsDiscussion;

    if (taskDetails != null) {
      if (refType == 3) {
        detailsLO = TaskDetailsLO.fromJson(taskDetails);
      } else if (refType == 1 || refType == 2) {
        detailsQuiz = TaskDetailsQuiz.fromJson(taskDetails);
      } else if (refType == 5) {
        detailsDiscussion = TaskDetailsDiscussion.fromJson(taskDetails);
      }
    }

    return Task(
      taskId: json['taskId'] as int,
      taskName: json['taskName'] as String? ?? '',
      referenceType: json['refrenceType'] as int? ?? refType,
      referenceTypeName: json['refrenceTypeName'] as String? ?? '',
      referenceTypeNameAr: json['refrenceTypeNameAr'] as String?,
      referenceId: json['refrenceId']?.toString() ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      dueDate: json['dueDate'] as String?,
      toDoListOrder: json['toDoListOrder'] as int? ?? 0,
      isShared: json['isShared'] as bool? ?? false,
      isOpened: json['isOpened'] as bool? ?? false,
      openDate: json['openDate'] as String?,
      isCompleted: json['isCompleted'] as bool?,
      completionDate: json['completionDate'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      courseId: json['courseId'] as int? ?? course?['id'] as int? ?? 0,
      courseName: course?['name'] as String?,
      courseArabicName: course?['arabicName'] as String?,
      courseImage: course?['image'] as String?,
      taskDetailsLO: detailsLO,
      taskDetailsQuiz: detailsQuiz,
      taskDetailsDiscussion: detailsDiscussion,
    );
  }

  /// Get display name for the task
  String get displayName {
    if (referenceType == 3 && taskDetailsLO != null) {
      return taskDetailsLO!.displayName;
    } else if ((referenceType == 1 || referenceType == 2) &&
        taskDetailsQuiz != null) {
      return taskDetailsQuiz!.name;
    } else if (referenceType == 5 && taskDetailsDiscussion != null) {
      return taskDetailsDiscussion!.title ?? taskName;
    }
    return taskName;
  }

  /// Get subtitle for the task card
  String get displaySubtitle {
    if (referenceType == 3 && taskDetailsLO != null) {
      return taskDetailsLO!.displayLessonName;
    } else if (referenceType == 5 && taskDetailsDiscussion != null) {
      // Strip HTML tags from content
      final content = taskDetailsDiscussion!.content ?? '';
      return content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }
    return courseArabicName ?? courseName ?? '';
  }

  /// Get task type display name in Arabic
  String get typeName {
    if (referenceTypeNameAr != null && referenceTypeNameAr!.isNotEmpty) {
      return referenceTypeNameAr!;
    }
    switch (referenceType) {
      case 1:
      case 2:
        return 'اختبار';
      case 3:
        return 'شرح';
      case 5:
        return 'نقاش';
      default:
        return 'مهمة';
    }
  }

  /// Get task color based on referenceType
  /// 3 = شرح (orange), 5 = نقاش (blue), 1,2 = تدريب/واجب (purple)
  Color get typeColor {
    switch (referenceType) {
      case 3:
        return const Color(0xFFFF9800); // Orange for شرح
      case 5:
        return const Color(0xFF0F6EB7); // Blue for نقاش
      case 1:
      case 2:
      default:
        return const Color(0xFF9C27B0); // Purple for تدريب/واجب
    }
  }

  /// Get task icon based on referenceType
  IconData get typeIcon {
    switch (referenceType) {
      case 3:
        return Icons.play_circle_outline; // شرح - video/explanation
      case 5:
        return Icons.chat_bubble_outline; // نقاش - discussion
      case 1:
      case 2:
      default:
        return Icons.assignment; // تدريب/واجب - assignment
    }
  }

  /// Get task image URL
  String? get imageUrl {
    if (referenceType == 3 && taskDetailsLO != null) {
      return taskDetailsLO!.displayImage;
    } else if ((referenceType == 1 || referenceType == 2) &&
        taskDetailsQuiz != null) {
      return taskDetailsQuiz!.displayImage;
    } else if (referenceType == 5 && taskDetailsDiscussion != null) {
      return taskDetailsDiscussion!.firstImageUrl;
    }
    return courseImage;
  }
}

/// Task group model (grouped by referenceType)
class TaskGroup {
  final int referenceType;
  final String referenceName;
  final String? referenceNameAr;
  final List<Task> tasks;

  TaskGroup({
    required this.referenceType,
    required this.referenceName,
    this.referenceNameAr,
    required this.tasks,
  });

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    final refType = json['referenceType'] as int;
    return TaskGroup(
      referenceType: refType,
      referenceName: json['refernceName'] as String? ?? '',
      referenceNameAr: json['refernceNameAr'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => Task.fromJson(t as Map<String, dynamic>, refType))
              .toList() ??
          [],
    );
  }
}

/// Response model for tasks by day API
class TasksByDayResponse {
  final bool status;
  final String message;
  final List<TaskGroup> taskGroups;

  TasksByDayResponse({
    required this.status,
    required this.message,
    required this.taskGroups,
  });

  factory TasksByDayResponse.fromJson(Map<String, dynamic> json) {
    return TasksByDayResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      taskGroups: (json['returnObject'] as List<dynamic>?)
              ?.map((g) => TaskGroup.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get all tasks flattened from all groups
  List<Task> get allTasks {
    return taskGroups.expand((group) => group.tasks).toList()
      ..sort((a, b) => a.toDoListOrder.compareTo(b.toDoListOrder));
  }

  /// Get count of incomplete tasks
  int get incompleteCount => allTasks.where((t) => !t.isOpened).length;

  /// Get count of completed tasks
  int get completedCount => allTasks.where((t) => t.isOpened).length;

  /// Get total task count
  int get totalCount => allTasks.length;
}
