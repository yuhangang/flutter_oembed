import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheManager extends Mock implements BaseCacheManager {}

void main() {
  group('EmbedScope', () {
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockCacheManager = MockCacheManager();
      EmbedScope.cacheManager = mockCacheManager;
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    testWidgets('configOf and styleOf', (tester) async {
      const config = EmbedConfig(style: EmbedStyle(maxScrollableHeight: 500));

      late EmbedConfig? capturedConfig;
      late EmbedStyle? capturedStyle;

      await tester.pumpWidget(
        EmbedScope(
          config: config,
          child: Builder(
            builder: (context) {
              capturedConfig = EmbedScope.configOf(context, listen: false);
              capturedStyle = EmbedScope.styleOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedConfig, equals(config));
      expect(capturedStyle, equals(config.style));
    });

    test('updateShouldNotify', () {
      const config1 = EmbedConfig(facebookAppId: '1');
      const config2 = EmbedConfig(facebookAppId: '2');

      const scope1 = EmbedScope(config: config1, child: SizedBox());
      const scope2 = EmbedScope(config: config1, child: SizedBox());
      const scope3 = EmbedScope(config: config2, child: SizedBox());

      expect(scope1.updateShouldNotify(scope2), isFalse);
      expect(scope1.updateShouldNotify(scope3), isTrue);
    });

    test('clearCache delegates to cache manager', () async {
      when(() => mockCacheManager.emptyCache()).thenAnswer((_) async {});

      await EmbedScope.clearCache();
      verify(() => mockCacheManager.emptyCache()).called(1);
    });

    test('evictCacheForUrl removes the resolved cache entry', () async {
      when(() => mockCacheManager.removeFile(any())).thenAnswer((_) async {});

      final didEvict = await EmbedScope.evictCacheForUrl(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        embedType: EmbedType.youtube,
        width: 640,
      );

      expect(didEvict, isTrue);
      verify(
        () => mockCacheManager.removeFile(
          any(that: contains('https://www.youtube.com/oembed')),
        ),
      ).called(1);
    });

    test('evictCacheForUrl returns false when no provider can be resolved',
        () async {
      final didEvict = await EmbedScope.evictCacheForUrl(
        'https://example.com/unknown',
      );

      expect(didEvict, isFalse);
      verifyNever(() => mockCacheManager.removeFile(any()));
    });
  });
}
