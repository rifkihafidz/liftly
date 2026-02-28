import 'package:flutter/foundation.dart';

/// Unified logging utility for the entire app.
///
/// Usage:
///   AppLogger.debug('MyTag', 'Some message');
///   AppLogger.info('MyTag', 'Some info');
///   AppLogger.warning('MyTag', 'A warning');
///   AppLogger.error('MyTag', 'An error', error, stackTrace);
class AppLogger {
  AppLogger._();

  /// Log a debug-level message. Only prints in debug mode.
  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Log an info-level message. Only prints in debug mode.
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Log a warning-level message. Only prints in debug mode.
  static void warning(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[⚠ $tag] $message');
    }
  }

  /// Log an error-level message. Only prints in debug mode.
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[✖ $tag] $message');
      if (error != null) debugPrint('[$tag] Error: $error');
      if (stackTrace != null) debugPrint('[$tag] Stack: $stackTrace');
    }
  }
}
