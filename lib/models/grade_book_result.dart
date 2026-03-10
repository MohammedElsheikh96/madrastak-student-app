class GradeBookResult {
  final List<CategoryResult> categoryResults;
  final double totalPercentage;

  GradeBookResult({
    required this.categoryResults,
    required this.totalPercentage,
  });

  factory GradeBookResult.fromJson(Map<String, dynamic> json) {
    return GradeBookResult(
      categoryResults: (json['categoryResults'] as List<dynamic>?)
              ?.map((e) => CategoryResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPercentage: (json['totalPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryResult {
  final String categoryName;
  final double weight;
  final List<Assignment> assignments;
  final double percentageScore;

  CategoryResult({
    required this.categoryName,
    required this.weight,
    required this.assignments,
    required this.percentageScore,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> json) {
    return CategoryResult(
      categoryName: json['categoryName'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => Assignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      percentageScore: (json['percentageScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Assignment {
  final String assignmentName;
  final double scorePercentage;
  final bool isSubmitted;
  final int? courseId;
  final String? externalQuizId;
  final String? quizUrl;

  Assignment({
    required this.assignmentName,
    required this.scorePercentage,
    this.isSubmitted = false,
    this.courseId,
    this.externalQuizId,
    this.quizUrl,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentName: json['assignmentName'] as String? ?? '',
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      courseId: json['courseId'] as int?,
      externalQuizId: json['externalQuizId'] as String?,
      quizUrl: json['quizUrl'] as String?,
    );
  }
}
