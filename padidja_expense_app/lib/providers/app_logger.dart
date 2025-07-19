import 'dart:developer' as developer;

/// Application logger utility
/// Provides a centralized logging system for the app
class AppLogger {
  static const String _defaultTag = 'PadidjaApp';
  
  /// Log levels
  static const int _levelDebug = 700;
  static const int _levelInfo = 800;
  static const int _levelWarning = 900;
  static const int _levelError = 1000;
  
  /// Whether to enable debug logging
  static bool _debugEnabled = true;
  
  /// Enable or disable debug logging
  static void setDebugEnabled(bool enabled) {
    _debugEnabled = enabled;
  }
  
  /// Log debug message
  static void debug(String message, {String? tag}) {
    if (_debugEnabled) {
      developer.log(
        message,
        name: tag ?? _defaultTag,
        level: _levelDebug,
      );
    }
  }
  
  /// Log info message
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: _levelInfo,
    );
  }
  
  /// Log warning message
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: _levelWarning,
    );
  }
  
  /// Log error message
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: _levelError,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log an exception with stack trace
  static void exception(String message, Object exception, StackTrace stackTrace, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: _levelError,
      error: exception,
      stackTrace: stackTrace,
    );
  }
  
  /// Log a database operation
  static void database(String operation, {String? details, String? tag}) {
    debug(
      'DB Operation: $operation${details != null ? ' - $details' : ''}',
      tag: tag ?? 'Database',
    );
  }
  
  /// Log a network operation
  static void network(String operation, {String? details, String? tag}) {
    debug(
      'Network: $operation${details != null ? ' - $details' : ''}',
      tag: tag ?? 'Network',
    );
  }
  
  /// Log a UI operation
  static void ui(String operation, {String? details, String? tag}) {
    debug(
      'UI: $operation${details != null ? ' - $details' : ''}',
      tag: tag ?? 'UI',
    );
  }
}