/// Quiz model for course/chapter quizzes
class Quiz {
  final String quizId;
  final String quizName;
  final int quizQuestionNumber;
  final double? result;
  final int passingPercentage;
  final String? image;
  final String? landscapeImage;
  final String? url;
  final String? createdAt;

  Quiz({
    required this.quizId,
    required this.quizName,
    required this.quizQuestionNumber,
    this.result,
    required this.passingPercentage,
    this.image,
    this.landscapeImage,
    this.url,
    this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['quizId'] as String,
      quizName: json['quizName'] as String,
      quizQuestionNumber: json['quizQuestionNumber'] as int? ?? 0,
      result: json['result'] != null ? (json['result'] as num).toDouble() : null,
      passingPercentage: json['passingPercentage'] as int? ?? 50,
      image: json['image'] as String?,
      landscapeImage: json['landscapeImage'] as String?,
      url: json['url'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// Learning Outcome (LO) model
class LearningOutcome {
  final int id;
  final String name;
  final String? arabicName;
  final String? shortDescription;
  final String? arabicShortDescription;
  final String? description;
  final String? arabicDescription;
  final bool isOpened;
  final int lessonPercentage;
  final int progress;
  final int lessonId;
  final int courseId;
  final String? content;
  final int type; // 4 = video, etc.
  final String? image;
  final String? imageAr;
  final String? portraitImage;
  final String? portraitImageAr;
  final int order;
  final bool isLiked;
  final bool intro;
  final List<Quiz> quizzes;

  LearningOutcome({
    required this.id,
    required this.name,
    this.arabicName,
    this.shortDescription,
    this.arabicShortDescription,
    this.description,
    this.arabicDescription,
    required this.isOpened,
    required this.lessonPercentage,
    required this.progress,
    required this.lessonId,
    required this.courseId,
    this.content,
    required this.type,
    this.image,
    this.imageAr,
    this.portraitImage,
    this.portraitImageAr,
    required this.order,
    required this.isLiked,
    required this.intro,
    required this.quizzes,
  });

  factory LearningOutcome.fromJson(Map<String, dynamic> json) {
    return LearningOutcome(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      shortDescription: json['shortDescription'] as String?,
      arabicShortDescription: json['arabicShortDescription'] as String?,
      description: json['description'] as String?,
      arabicDescription: json['arabicDescription'] as String?,
      isOpened: json['isOpened'] as bool? ?? false,
      lessonPercentage: json['lessonPercentage'] as int? ?? 0,
      progress: json['progress'] as int? ?? 0,
      lessonId: json['lessonId'] as int? ?? 0,
      courseId: json['courseId'] as int? ?? 0,
      content: json['content'] as String?,
      type: json['type'] as int? ?? 0,
      image: json['image'] as String?,
      imageAr: json['imageAr'] as String?,
      portraitImage: json['portraitImage'] as String?,
      portraitImageAr: json['portraitImageAr'] as String?,
      order: json['order'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      intro: json['intro'] as bool? ?? false,
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get displayName => arabicName ?? name;
  String get displayImage => portraitImage ?? image ?? '';
}

/// Lesson model
class Lesson {
  final int id;
  final String name;
  final String? arabicName;
  final String? description;
  final String? fileUrl;
  final int order;
  final String? duration;
  final String? arabicDuration;
  final int lessonType;
  final int lessonStatus;
  final int progress;
  final String? outcome;
  final String? arabicOutcome;
  final String? image;
  final bool intro;
  final int chapterId;
  final int courseId;
  final bool locked;
  final bool isOpened;
  final int lessonPercentage;
  final double? quizPercentage;
  final bool? quizPassed;
  final bool isQuizOpened;
  final List<LearningOutcome> lessonLOs;
  final List<Quiz> quizzes;
  final List<Quiz> internalQuizzes;

  Lesson({
    required this.id,
    required this.name,
    this.arabicName,
    this.description,
    this.fileUrl,
    required this.order,
    this.duration,
    this.arabicDuration,
    required this.lessonType,
    required this.lessonStatus,
    required this.progress,
    this.outcome,
    this.arabicOutcome,
    this.image,
    required this.intro,
    required this.chapterId,
    required this.courseId,
    required this.locked,
    required this.isOpened,
    required this.lessonPercentage,
    this.quizPercentage,
    this.quizPassed,
    required this.isQuizOpened,
    required this.lessonLOs,
    required this.quizzes,
    required this.internalQuizzes,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      description: json['description'] as String?,
      fileUrl: json['fileUrl'] as String?,
      order: json['order'] as int? ?? 0,
      duration: json['duration'] as String?,
      arabicDuration: json['arabicDuration'] as String?,
      lessonType: json['lessonType'] as int? ?? 0,
      lessonStatus: json['lessonStatus'] as int? ?? 0,
      progress: json['progress'] as int? ?? 0,
      outcome: json['outcome'] as String?,
      arabicOutcome: json['arabicOutcome'] as String?,
      image: json['image'] as String?,
      intro: json['intro'] as bool? ?? false,
      chapterId: json['chapterId'] as int? ?? 0,
      courseId: json['courseId'] as int? ?? 0,
      locked: json['locked'] as bool? ?? false,
      isOpened: json['isOpened'] as bool? ?? false,
      lessonPercentage: json['lessonPercentage'] as int? ?? 0,
      quizPercentage: json['quizPercentage'] != null
          ? (json['quizPercentage'] as num).toDouble()
          : null,
      quizPassed: json['quizPassed'] as bool?,
      isQuizOpened: json['isQuizOpened'] as bool? ?? false,
      lessonLOs: (json['lessonLOs'] as List<dynamic>?)
              ?.map((lo) => LearningOutcome.fromJson(lo as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      internalQuizzes: (json['internalQuizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get displayName => arabicName ?? name;
}

/// Chapter model
class Chapter {
  final int id;
  final String name;
  final String? arabicName;
  final String? description;
  final String? arabicDescription;
  final double originalFees;
  final double? discountPercentage;
  final double finalFees;
  final String? duration;
  final String? arabicDuration;
  final String? outcome;
  final String? arabicOutcome;
  final bool isAscending;
  final int order;
  final int chapterStatus;
  final int courseId;
  final String? releaseDate;
  final String? expirationDate;
  final bool subscribed;
  final bool isLifeTime;
  final List<Lesson> lessons;
  final List<Quiz> quizzes;
  final List<Quiz> internalQuizzes;

  Chapter({
    required this.id,
    required this.name,
    this.arabicName,
    this.description,
    this.arabicDescription,
    required this.originalFees,
    this.discountPercentage,
    required this.finalFees,
    this.duration,
    this.arabicDuration,
    this.outcome,
    this.arabicOutcome,
    required this.isAscending,
    required this.order,
    required this.chapterStatus,
    required this.courseId,
    this.releaseDate,
    this.expirationDate,
    required this.subscribed,
    required this.isLifeTime,
    required this.lessons,
    required this.quizzes,
    required this.internalQuizzes,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      description: json['description'] as String?,
      arabicDescription: json['arabicDescription'] as String?,
      originalFees: (json['originalFees'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: json['discountPercentage'] != null
          ? (json['discountPercentage'] as num).toDouble()
          : null,
      finalFees: (json['finalFees'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String?,
      arabicDuration: json['arabicDuration'] as String?,
      outcome: json['outcome'] as String?,
      arabicOutcome: json['arabicOutcome'] as String?,
      isAscending: json['isAscending'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      chapterStatus: json['chapterStatus'] as int? ?? 0,
      courseId: json['courseId'] as int? ?? 0,
      releaseDate: json['releaseDate'] as String?,
      expirationDate: json['expirationDate'] as String?,
      subscribed: json['subscribed'] as bool? ?? false,
      isLifeTime: json['isLifeTime'] as bool? ?? false,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((l) => Lesson.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      internalQuizzes: (json['internalQuizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get displayName => arabicName ?? name;
}

/// Response model for chapters and lessons API
class ChaptersLessonsResponse {
  final List<Quiz> quizzes;
  final List<Quiz> internalQuizzes;
  final List<Chapter> chapters;

  ChaptersLessonsResponse({
    required this.quizzes,
    required this.internalQuizzes,
    required this.chapters,
  });

  factory ChaptersLessonsResponse.fromJson(Map<String, dynamic> json) {
    return ChaptersLessonsResponse(
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      internalQuizzes: (json['internalQuizzes'] as List<dynamic>?)
              ?.map((q) => Quiz.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((c) => Chapter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Extended course details model
class CourseDetails {
  final int id;
  final String name;
  final String? arabicName;
  final String? description;
  final String? arabicDescription;
  final double originalFees;
  final double discountPercentage;
  final double finalFees;
  final String? duration;
  final String? arabicDuration;
  final String? image;
  final String? coverImage;
  final String? introVideoUrl;
  final int status;
  final int numOfSales;
  final double rate;
  final String? releaseDate;
  final String? expirationDate;
  final String? teacherId;
  final int? countryId;
  final bool isLifeTime;
  final int? categoryId;
  final int numOfChapters;
  final int numOfLessons;
  final bool isLive;
  final bool bundleOnly;
  final bool? isDeleted;
  final bool courseSubscribed;
  final int percentage;
  final String? teacherFirstName;
  final String? teacherLastName;
  final String? teacherProfilePictureUrl;
  final int numOfLessonsFinished;
  final int numOfLOs;
  final List<String>? chaptersNames;

  CourseDetails({
    required this.id,
    required this.name,
    this.arabicName,
    this.description,
    this.arabicDescription,
    required this.originalFees,
    required this.discountPercentage,
    required this.finalFees,
    this.duration,
    this.arabicDuration,
    this.image,
    this.coverImage,
    this.introVideoUrl,
    required this.status,
    required this.numOfSales,
    required this.rate,
    this.releaseDate,
    this.expirationDate,
    this.teacherId,
    this.countryId,
    required this.isLifeTime,
    this.categoryId,
    required this.numOfChapters,
    required this.numOfLessons,
    required this.isLive,
    required this.bundleOnly,
    this.isDeleted,
    required this.courseSubscribed,
    required this.percentage,
    this.teacherFirstName,
    this.teacherLastName,
    this.teacherProfilePictureUrl,
    required this.numOfLessonsFinished,
    required this.numOfLOs,
    this.chaptersNames,
  });

  factory CourseDetails.fromJson(Map<String, dynamic> json) {
    return CourseDetails(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      arabicName: json['arabicName'] as String?,
      description: json['description'] as String?,
      arabicDescription: json['arabicDescription'] as String?,
      originalFees: (json['originalFees'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      finalFees: (json['finalFees'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String?,
      arabicDuration: json['arabicDuration'] as String?,
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      introVideoUrl: json['introVideoUrl'] as String?,
      status: json['status'] as int? ?? 0,
      numOfSales: json['numOfSales'] as int? ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['releaseDate'] as String?,
      expirationDate: json['expirationDate'] as String?,
      teacherId: json['teacherId'] as String?,
      countryId: json['countryId'] as int?,
      isLifeTime: json['isLifeTime'] as bool? ?? false,
      categoryId: json['categoryId'] as int?,
      numOfChapters: json['numOfChapters'] as int? ?? 0,
      numOfLessons: json['numOfLessons'] as int? ?? 0,
      isLive: json['isLive'] as bool? ?? false,
      bundleOnly: json['bundleOnly'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool?,
      courseSubscribed: json['courseSubscribed'] as bool? ?? false,
      percentage: json['percentage'] as int? ?? 0,
      teacherFirstName: json['teacher_firstName'] as String?,
      teacherLastName: json['teacher_lastName'] as String?,
      teacherProfilePictureUrl: json['teacher_ProfilePictureUrl'] as String?,
      numOfLessonsFinished: json['numOfLessonsFinishied'] as int? ?? 0,
      numOfLOs: json['numOfLOs'] as int? ?? 0,
      chaptersNames: (json['chaptersNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  String get displayName => arabicName ?? name;
  String get teacherFullName => '${teacherFirstName ?? ''} ${teacherLastName ?? ''}'.trim();
}
