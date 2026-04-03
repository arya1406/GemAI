import 'package:uuid/uuid.dart';

/// Provides UUID generation utilities.
class UuidUtil {
  UuidUtil._();

  static const _uuid = Uuid();

  /// Generates a new v4 UUID string.
  static String generate() => _uuid.v4();
}
