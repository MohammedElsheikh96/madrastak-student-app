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
  final List<Assignment> assignments;

  CategoryResult({
    required this.categoryName,
    required this.assignments,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> json) {
    return CategoryResult(
      categoryName: json['categoryName'] as String? ?? '',
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => Assignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Assignment {
  final String assignmentName;
  final double scorePercentage;
  final String? assignmentId;

  Assignment({
    required this.assignmentName,
    required this.scorePercentage,
    this.assignmentId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentName: json['assignmentName'] as String? ?? '',
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      assignmentId: json['assignmentId'] as String?,
    );
  }
}
