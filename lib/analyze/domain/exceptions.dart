class AnalyzeException implements Exception {
  final String message;

  const AnalyzeException(this.message);

  @override
  String toString() => message;
}
