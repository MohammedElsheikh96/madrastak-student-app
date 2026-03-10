/// Model for live session from GetLiveSessions API
class LiveSession {
  final int id;
  final String name;
  final String? arabicName;
  final String? courseName;
  final String? courseArabicName;
  final int courseId;
  final String? image;
  final String? imageAr;
  final int type;
  final int? lessonId;
  final String? meetingLink;
  final int status; // 1 = active/live
  final String? startDate;
  final String? endDate;

  LiveSession({
    required this.id,
    required this.name,
    this.arabicName,
    this.courseName,
    this.courseArabicName,
    required this.courseId,
    this.image,
    this.imageAr,
    required this.type,
    this.lessonId,
    this.meetingLink,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      courseName: json['courseName'] as String?,
      courseArabicName: json['courseArabicName'] as String?,
      courseId: json['courseId'] as int? ?? 0,
      image: json['image'] as String?,
      imageAr: json['imageAr'] as String?,
      type: json['type'] as int? ?? 0,
      lessonId: json['lessonId'] as int?,
      meetingLink: json['meetingLink'] as String?,
      status: json['status'] as int? ?? 0,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );
  }

  String get displayName => arabicName ?? name;
  String get displayCourseName => courseArabicName ?? courseName ?? '';
  String get displayImage => image ?? imageAr ?? '';

  bool get isLive {
    if (startDate == null || endDate == null) return false;
    final now = DateTime.now();
    final start = DateTime.tryParse(startDate!);
    final end = DateTime.tryParse(endDate!);
    if (start == null || end == null) return false;
    return now.isAfter(start) && now.isBefore(end);
  }

  String get timeRange {
    final start = DateTime.tryParse(startDate ?? '');
    final end = DateTime.tryParse(endDate ?? '');
    if (start == null || end == null) return '';
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

/// Model for recommended video from GetRecommendedContent API
class RecommendedVideo {
  final int id;
  final String name;
  final String? arabicName;
  final String? content; // video URL
  final int type;
  final int? lessonId;
  final String? image;
  final String? imageAr;
  final int? courseId;
  final String? courseName;
  final String? courseArabicName;

  RecommendedVideo({
    required this.id,
    required this.name,
    this.arabicName,
    this.content,
    required this.type,
    this.lessonId,
    this.image,
    this.imageAr,
    this.courseId,
    this.courseName,
    this.courseArabicName,
  });

  factory RecommendedVideo.fromJson(Map<String, dynamic> json) {
    return RecommendedVideo(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      content: json['content'] as String?,
      type: json['type'] as int? ?? 0,
      lessonId: json['lessonId'] as int?,
      image: json['image'] as String?,
      imageAr: json['imageAr'] as String?,
      courseId: json['courseId'] as int?,
      courseName: json['courseName'] as String?,
      courseArabicName: json['courseArabicName'] as String?,
    );
  }

  String get displayName => arabicName ?? name;
  String get displayCourseName => courseArabicName ?? courseName ?? '';
  String get displayImage => image ?? imageAr ?? '';
  String get videoUrl => content ?? '';
}
