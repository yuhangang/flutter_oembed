import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';

void main() {
  group('EmbedLogger', () {
    test('should not emit events when the logger is disabled', () {
      var callCount = 0;
      final logger = EmbedLogger(
        enabled: false,
        sink: ({required level, required message, data, error, stackTrace}) {
          callCount++;
        },
      );

      logger.info('hidden');

      expect(callCount, 0);
    });

    test('should respect the configured log level threshold', () {
      final events = <String>[];
      final logger = EmbedLogger.enabled(
        level: EmbedLogLevel.info,
        sink: ({required level, required message, data, error, stackTrace}) {
          events.add('${level.name}:$message');
        },
      );

      logger.debug('debug');
      logger.info('info');
      logger.warning('warning');
      logger.error('error');

      expect(events, ['info:info', 'warning:warning', 'error:error']);
    });

    test('should forward all messages when the logger is in debug mode', () {
      final events = <String>[];
      final logger = EmbedLogger.debug(
        sink: ({required level, required message, data, error, stackTrace}) {
          events.add('${level.name}:$message');
        },
      );

      logger.debug('visible');

      expect(events, ['debug:visible']);
    });
  });
}
