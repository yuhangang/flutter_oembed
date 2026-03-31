import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/logging/embed_logger.dart';

void main() {
  group('EmbedLogger', () {
    test('disabled logger does not emit events', () {
      var callCount = 0;
      final logger = EmbedLogger(
        enabled: false,
        sink: ({required level, required message, error, stackTrace}) {
          callCount++;
        },
      );

      logger.info('hidden');

      expect(callCount, 0);
    });

    test('respects the configured level threshold', () {
      final events = <String>[];
      final logger = EmbedLogger.enabled(
        level: EmbedLogLevel.info,
        sink: ({required level, required message, error, stackTrace}) {
          events.add('${level.name}:$message');
        },
      );

      logger.debug('debug');
      logger.info('info');
      logger.warning('warning');
      logger.error('error');

      expect(events, ['info:info', 'warning:warning', 'error:error']);
    });

    test('debug logger forwards messages in debug mode', () {
      final events = <String>[];
      final logger = EmbedLogger.debug(
        sink: ({required level, required message, error, stackTrace}) {
          events.add('${level.name}:$message');
        },
      );

      logger.debug('visible');

      expect(events, ['debug:visible']);
    });
  });
}
