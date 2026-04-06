import 'package:flutter/foundation.dart';

/// Severity levels supported by [EmbedLogger].
enum EmbedLogLevel {
  off,
  error,
  warning,
  info,
  debug,
}

/// Signature used for custom log sinks.
typedef EmbedLogSink = void Function({
  required EmbedLogLevel level,
  required String message,
  Map<String, dynamic>? data,
  Object? error,
  StackTrace? stackTrace,
});

/// Configurable logger for the OEmbed package.
///
/// By default the logger is disabled. Use [EmbedLogger.debug] for a debug-only
/// console logger, or [EmbedLogger.enabled] to emit logs in all build modes
/// with a custom sink.
class EmbedLogger {
  final bool enabled;
  final EmbedLogLevel level;
  final bool debugOnly;
  final String tag;
  final EmbedLogSink? sink;

  const EmbedLogger({
    this.enabled = false,
    this.level = EmbedLogLevel.debug,
    this.debugOnly = true,
    this.tag = 'OEmbed',
    this.sink,
  });

  const EmbedLogger.disabled()
      : enabled = false,
        level = EmbedLogLevel.off,
        debugOnly = true,
        tag = 'OEmbed',
        sink = null;

  const EmbedLogger.debug({
    this.level = EmbedLogLevel.debug,
    this.tag = 'OEmbed',
    this.sink,
  })  : enabled = true,
        debugOnly = true;

  const EmbedLogger.enabled({
    this.level = EmbedLogLevel.debug,
    this.debugOnly = false,
    this.tag = 'OEmbed',
    this.sink,
  })  : enabled = true;

  bool get isActive =>
      enabled && level != EmbedLogLevel.off && (!debugOnly || kDebugMode);

  bool shouldLog(EmbedLogLevel messageLevel) {
    if (!isActive) return false;
    return messageLevel.index <= level.index;
  }

  void log(
    EmbedLogLevel messageLevel,
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!shouldLog(messageLevel)) return;

    final handler = sink ?? _defaultSink;
    handler(
      level: messageLevel,
      message: message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        EmbedLogLevel.error,
        message,
        data: data,
        error: error,
        stackTrace: stackTrace,
      );

  void warning(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        EmbedLogLevel.warning,
        message,
        data: data,
        error: error,
        stackTrace: stackTrace,
      );

  void info(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        EmbedLogLevel.info,
        message,
        data: data,
        error: error,
        stackTrace: stackTrace,
      );

  void debug(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        EmbedLogLevel.debug,
        message,
        data: data,
        error: error,
        stackTrace: stackTrace,
      );

  void _defaultSink({
    required EmbedLogLevel level,
    required String message,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final prefix = '[$tag][${level.name}]';
    final sb = StringBuffer('$prefix $message');

    if (data != null && data.isNotEmpty) {
      sb.write(' | data: $data');
    }

    debugPrint(sb.toString());

    if (error != null) {
      debugPrint('$prefix error: $error');
    }
    if (stackTrace != null) {
      debugPrint('$prefix stackTrace: $stackTrace');
    }
  }
}
