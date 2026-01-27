class ApiException implements Exception {
  final bool success;
  final String statusCode;
  final String message;

  ApiException({
    required this.success,
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
