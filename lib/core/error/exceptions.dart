/// Exception thrown by the AI remote data source.
class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => 'AiException: $message';
}

/// Exception thrown by the local database data source.
class DatabaseException implements Exception {
  const DatabaseException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}
