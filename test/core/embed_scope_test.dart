import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheProvider extends Mock implements EmbedCacheProvider {}

void main() {
  group('EmbedScope', () {
    late MockCacheProvider mockCacheProvider;
    late EmbedConfig configWithCacheProvider;

    setUp(() {
      mockCacheProvider = MockCacheProvider();
      configWithCacheProvider = EmbedConfig(cacheProvider: mockCacheProvider);
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

    test('clearCache delegates to the configured cache provider', () async {
      when(() => mockCacheProvider.emptyCache()).thenAnswer((_) async {});

      await EmbedScope.clearCache(config: configWithCacheProvider);
      verify(() => mockCacheProvider.emptyCache()).called(1);
    });

    test(
        'evictCacheForUrl removes the resolved entry from the configured cache provider',
        () async {
      when(() => mockCacheProvider.removeFile(any())).thenAnswer((_) async {});

      final didEvict = await EmbedScope.evictCacheForUrl(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        config: configWithCacheProvider,
        embedType: EmbedType.youtube,
        width: 640,
      );

      expect(didEvict, isTrue);
      verify(
        () => mockCacheProvider.removeFile(
          any(that: contains('https://www.youtube.com/oembed')),
        ),
      ).called(1);
    });

    test('evictCacheForUrl returns false when no provider can be resolved',
        () async {
      final didEvict = await EmbedScope.evictCacheForUrl(
        'https://example.com/unknown',
        config: configWithCacheProvider,
      );

      expect(didEvict, isFalse);
      verifyNever(() => mockCacheProvider.removeFile(any()));
    });
  });
}
