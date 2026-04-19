import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_constant.dart';
import 'package:flutter_oembed/src/models/core/embed_constraints.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/configs/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/core/embed_strings.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/models/core/embed_style.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEmbedCacheProvider implements EmbedCacheProvider {
  const _FakeEmbedCacheProvider();

  @override
  Future<void> emptyCache() async {}

  @override
  Future<Uint8List?> getFileFromCache(String key) async => null;

  @override
  Future<void> putFile(String key, Uint8List bytes, {Duration? maxAge}) async {}

  @override
  Future<void> removeFile(String key) async {}
}

void main() {
  group('EmbedProviderConfig', () {
    test('isEnabled', () {
      final config = EmbedProviderConfig(
        providers: EmbedProviders.verified
            .where((r) => r.providerName == 'YouTube')
            .toList(),
      );
      expect(config.isEnabled('YouTube'), isTrue);
      expect(config.isEnabled('Vimeo'), isFalse);

      const configAll = EmbedProviderConfig();
      expect(configAll.isEnabled('Vimeo'), isTrue);
    });

    test('getRenderMode', () {
      const config = EmbedProviderConfig(
        providerRenderModes: {'YouTube': EmbedRenderMode.iframe},
      );
      expect(config.getRenderMode('YouTube'), equals(EmbedRenderMode.iframe));
      expect(
        resolveEmbedRenderMode('Vimeo', overrides: const {}, isWeb: false),
        equals(EmbedRenderMode.oembed),
      );
    });

    test('Flutter Web defaults iframe-friendly providers to iframe mode', () {
      expect(
        resolveEmbedRenderMode('YouTube', overrides: const {}, isWeb: true),
        equals(EmbedRenderMode.iframe),
      );
      expect(
        resolveEmbedRenderMode('Vimeo', overrides: const {}, isWeb: true),
        equals(EmbedRenderMode.iframe),
      );
      expect(
        resolveEmbedRenderMode('Spotify', overrides: const {}, isWeb: true),
        equals(EmbedRenderMode.iframe),
      );
      expect(
        resolveEmbedRenderMode('TikTok', overrides: const {}, isWeb: true),
        equals(EmbedRenderMode.iframe),
      );
      expect(
        resolveEmbedRenderMode('Reddit', overrides: const {}, isWeb: true),
        equals(EmbedRenderMode.oembed),
      );
    });

    test('explicit render mode overrides win on Flutter Web', () {
      expect(
        resolveEmbedRenderMode(
          'YouTube',
          overrides: const {'YouTube': EmbedRenderMode.oembed},
          isWeb: true,
        ),
        equals(EmbedRenderMode.oembed),
      );
    });

    test('copyWith', () {
      const config = EmbedProviderConfig();
      final updated = config.copyWith(
        providers: EmbedProviders.verified
            .where((r) => r.providerName == 'YouTube')
            .toList(),
      );
      expect(updated.isEnabled('YouTube'), isTrue);
      expect(updated.isEnabled('Vimeo'), isFalse);
    });

    test('copyWith can reset providers to the default verified registry', () {
      final customOnly = EmbedProviderConfig(
        providers: EmbedProviders.verified
            .where((r) => r.providerName == 'YouTube')
            .toList(),
      );

      final reset = customOnly.copyWith(providers: null);

      expect(reset.providers, isNull);
      expect(reset.isEnabled('YouTube'), isTrue);
      expect(reset.isEnabled('Tumblr'), isTrue);
    });

    test('explicit providers override default registry', () {
      final config = const EmbedProviderConfig(
        providers: [
          EmbedProviderRule(
            pattern: r'^https?:\/\/(?:www\.)?pinterest\.com\/.*$',
            endpoint: 'https://www.pinterest.com/oembed.json',
            providerName: 'Pinterest',
          ),
        ],
      );

      expect(config.isEnabled('Pinterest'), isTrue);
      // The default registry is fully replaced
      expect(config.isEnabled('YouTube'), isFalse);
    });

    test('EmbedProviders extension append', () {
      const customRule = EmbedProviderRule(
        pattern: r'',
        endpoint: '',
        providerName: 'Custom',
      );

      final merged = EmbedProviders.verified.append([customRule]);
      expect(merged.any((p) => p.providerName == 'Custom'), isTrue);
      expect(merged.any((p) => p.providerName == 'YouTube'), isTrue);
    });

    test('EmbedProviders getters are defensive copies', () {
      final verified = EmbedProviders.verified;
      final all = EmbedProviders.all;

      expect(
          () => verified.add(const EmbedProviderRule(
                pattern: r'',
                endpoint: '',
                providerName: 'Custom Verified',
              )),
          throwsUnsupportedError);
      expect(
          () => all.add(const EmbedProviderRule(
                pattern: r'',
                endpoint: '',
                providerName: 'Custom All',
              )),
          throwsUnsupportedError);
    });

    test('matchRule memoizes provider resolution by URL', () {
      const config = EmbedProviderConfig();
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

      final first = config.matchRule(url);
      final second = config.matchRule(url);

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    });
  });

  group('EmbedConfig', () {
    test('copyWith', () {
      const config = EmbedConfig();
      const cacheProvider = _FakeEmbedCacheProvider();
      final routeObserver = RouteObserver<ModalRoute<dynamic>>();
      final updated = config.copyWith(
        facebookAppId: 'new',
        cacheProvider: cacheProvider,
        pauseOnRouteCover: true,
        routeObserver: routeObserver,
        strings: const EmbedStrings(
          loadingSemanticsLabel: 'Memuat kandungan',
        ),
      );
      expect(updated.facebookAppId, equals('new'));
      expect(updated.cacheProvider, same(cacheProvider));
      expect(updated.pauseOnRouteCover, isTrue);
      expect(updated.routeObserver, same(routeObserver));
      expect(
        updated.strings.loadingSemanticsLabel,
        equals('Memuat kandungan'),
      );
      expect(updated.heightUpdateDeltaThreshold, equals(2.0));
    });

    test('defaults use shared embed constants', () {
      const config = EmbedConfig();
      const style = EmbedStyle();

      expect(config.loadTimeout, equals(kDefaultEmbedLoadTimeout));
      expect(
        config.heightUpdateDeltaThreshold,
        equals(kDefaultHeightUpdateDeltaThreshold),
      );
      expect(
        style.maxScrollableHeight,
        equals(kDefaultMaxScrollableEmbedHeight),
      );
    });

    test('runtimeEquals includes callback identity', () {
      void handleTap(String url, EmbedData? data) {}

      final first = EmbedConfig(onLinkTap: handleTap);
      final second = first.copyWith(onLinkTap: handleTap);
      final third = EmbedConfig(onLinkTap: (url, data) {});

      expect(first.runtimeEquals(second), isTrue);
      expect(first.runtimeEquals(third), isFalse);
    });
  });

  group('EmbedConstraints', () {
    test('clampHeight applies min and max bounds', () {
      const constraints = EmbedConstraints(minHeight: 120, maxHeight: 240);

      expect(constraints.clampHeight(80), equals(120));
      expect(constraints.clampHeight(180), equals(180));
      expect(constraints.clampHeight(400), equals(240));
    });

    test('copyWith preserves unspecified values', () {
      const constraints = EmbedConstraints(
        preferredHeight: 152,
        minHeight: 120,
      );

      final updated = constraints.copyWith(maxHeight: 300);

      expect(updated.preferredHeight, equals(152));
      expect(updated.minHeight, equals(120));
      expect(updated.maxHeight, equals(300));
    });

    test('copyWith can explicitly clear fields', () {
      const constraints = EmbedConstraints(
        preferredHeight: 232,
        minHeight: 180,
        maxHeight: 320,
      );

      final updated = constraints.copyWith(
        preferredHeight: null,
        minHeight: null,
      );

      expect(updated.preferredHeight, isNull);
      expect(updated.minHeight, isNull);
      expect(updated.maxHeight, equals(320));
    });

    test('rejects negative preferredHeight', () {
      expect(
        () => EmbedConstraints(preferredHeight: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
