import 'package:flutter/foundation.dart';

/// Severity levels supported by [OembedLogger].
enum OembedLogLevel {
  off,
  error,
  warning,
  info,
  debug,
}

/// Signature used for custom log sinks.
typedef OembedLogSink = void Function({
  required OembedLogLevel level,
  required String message,
  Object? error,
  StackTrace? stackTrace,
});

/// Configurable logger for the OEmbed package.
///
/// By default the logger is disabled. Use [OembedLogger.debug] for a debug-only
/// console logger, or [OembedLogger.enabled] to emit logs in all build modes
/// with a custom sink.
class OembedLogger {
  final bool enabled;
  final OembedLogLevel level;
  final bool debugOnly;
  final String tag;
  final OembedLogSink? sink;

  const OembedLogger({
    this.enabled = false,
    this.level = OembedLogLevel.debug,
    this.debugOnly = true,
    this.tag = 'OEmbed',
    this.sink,
  });

  const OembedLogger.disabled()
      : enabled = false,
        level = OembedLogLevel.off,
        debugOnly = true,
        tag = 'OEmbed',
        sink = null;

  const OembedLogger.debug({
    this.level = OembedLogLevel.debug,
    this.tag = 'OEmbed',
    this.sink,
  })  : enabled = true,
        debugOnly = true;

  const OembedLogger.enabled({
    this.level = OembedLogLevel.debug,
    this.debugOnly = false,
    this.tag = 'OEmbed',
    this.sink,
  })  : enabled = true;

  bool get isActive =>
      enabled && level != OembedLogLevel.off && (!debugOnly || kDebugMode);

  bool shouldLog(OembedLogLevel messageLevel) {
    if (!isActive) return false;
    return messageLevel.index <= level.index;
  }

  void log(
    OembedLogLevel messageLevel,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!shouldLog(messageLevel)) return;

    final handler = sink ?? _defaultSink;
    handler(
      level: messageLevel,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(OembedLogLevel.error, message, error: error, stackTrace: stackTrace);

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        OembedLogLevel.warning,
        message,
        error: error,
        stackTrace: stackTrace,
      );

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(OembedLogLevel.info, message, error: error, stackTrace: stackTrace);

  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(OembedLogLevel.debug, message, error: error, stackTrace: stackTrace);

  void _defaultSink({
    required OembedLogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final prefix = '[$tag][${level.name}]';
    debugPrint('$prefix $message');
    if (error != null) {
      debugPrint('$prefix error: $error');
    }
    if (stackTrace != null) {
      debugPrint('$prefix stackTrace: $stackTrace');
    }
  }
}
