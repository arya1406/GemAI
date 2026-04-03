/// Base class for domain-level failures.
abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Failure from the AI data source.
class AiFailure extends Failure {
  const AiFailure(super.message);
}

/// Failure from the local database.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Failure due to no network connection.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Failure caused by unexpected conditions.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
