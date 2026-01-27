class CourseColor {
  final int id;
  final String? name;
  final String code;

  CourseColor({
    required this.id,
    this.name,
    required this.code,
  });

  factory CourseColor.fromJson(Map<String, dynamic> json) {
    return CourseColor(
      id: json['id'] as int,
      name: json['name'] as String?,
      code: json['code'] as String,
    );
  }
}

class Course {
  final int id;
  final String name;
  final String? arabicName;
  final String? duration;
  final String? arabicDuration;
  final String? image;
  final String? coverImage;
  final int status;
  final int numOfSales;
  final double rate;
  final String? releaseDate;
  final String? expirationDate;
  final bool isLifeTime;
  final bool? isDeleted;
  final bool courseSubscribed;
  final int enrollmentType;
  final String? createdAt;
  final int type;
  final bool isLive;
  final int numOfTasks;
  final double completedTasksPercentage;
  final bool bundleOnly;
  final int? order;
  final CourseColor? color;
  final int? colorId;

  Course({
    required this.id,
    required this.name,
    this.arabicName,
    this.duration,
    this.arabicDuration,
    this.image,
    this.coverImage,
    required this.status,
    required this.numOfSales,
    required this.rate,
    this.releaseDate,
    this.expirationDate,
    required this.isLifeTime,
    this.isDeleted,
    required this.courseSubscribed,
    required this.enrollmentType,
    this.createdAt,
    required this.type,
    required this.isLive,
    required this.numOfTasks,
    required this.completedTasksPercentage,
    required this.bundleOnly,
    this.order,
    this.color,
    this.colorId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      name: json['name'] as String,
      arabicName: json['arabicName'] as String?,
      duration: json['duration'] as String?,
      arabicDuration: json['arabicDuration'] as String?,
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      status: json['status'] as int,
      numOfSales: json['numOfSales'] as int,
      rate: (json['rate'] as num).toDouble(),
      releaseDate: json['releaseDate'] as String?,
      expirationDate: json['expirationDate'] as String?,
      isLifeTime: json['isLifeTime'] as bool,
      isDeleted: json['isDeleted'] as bool?,
      courseSubscribed: json['courseSubscribed'] as bool,
      enrollmentType: json['enrollmentType'] as int,
      createdAt: json['createdAt'] as String?,
      type: json['type'] as int,
      isLive: json['isLive'] as bool,
      numOfTasks: json['numOfTasks'] as int,
      completedTasksPercentage: (json['completedTasksPercentage'] as num).toDouble(),
      bundleOnly: json['bundleOnly'] as bool,
      order: json['order'] as int?,
      color: json['color'] != null ? CourseColor.fromJson(json['color']) : null,
      colorId: json['colorId'] as int?,
    );
  }

  String get displayName => arabicName ?? name;
}
