import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/provider_strategies.dart';
import 'package:flutter_embed/src/models/provider_rule.dart';
import 'package:flutter_embed/src/services/api/tiktok_embed_api.dart';
import 'package:flutter_embed/src/services/api/x_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Provider Strategies', () {
    test('YouTubeProviderStrategy returns correct user agent and base URL', () {
      const strategy = YouTubeProviderStrategy();
      expect(strategy.userAgent, contains('Chrome'));
      expect(strategy.resolveBaseUrl(null),
          equals('https://www.youtube-nocookie.com'));
    });

    test('TikTokProviderStrategy creates TikTokEmbedApi', () {
      const strategy = TikTokProviderStrategy();
      const context = EmbedProviderContext(
        url: 'https://www.tiktok.com/video/123',
        resolvedEndpoint: 'https://www.tiktok.com/oembed',
        strategy: strategy,
        width: 640.0,
        locale: 'en',
        brightness: Brightness.light,
        facebookAppId: '',
        facebookClientToken: '',
      );
      final api = strategy.createApi(context);

      expect(api, isA<TikTokEmbedApi>());
    });

    test('XProviderStrategy creates XEmbedApi', () {
      const strategy = XProviderStrategy();
      const context = EmbedProviderContext(
        url: 'https://x.com/user/status/123',
        resolvedEndpoint: 'https://publish.twitter.com/oembed',
        strategy: strategy,
        width: 640.0,
        locale: 'en',
        brightness: Brightness.light,
        facebookAppId: '',
        facebookClientToken: '',
      );
      final api = strategy.createApi(context);

      expect(api, isA<XEmbedApi>());
    });

    test(
        'YouTubeProviderStrategy creates GenericEmbedApi with YouTube endpoint',
        () {
      const strategy = YouTubeProviderStrategy();
      const context = EmbedProviderContext(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        resolvedEndpoint: 'https://www.youtube.com/oembed',
        strategy: strategy,
        width: 640.0,
        locale: 'en',
        brightness: Brightness.light,
        facebookAppId: '',
        facebookClientToken: '',
      );
      final api = strategy.createApi(context);

      expect(api.baseUrl, equals('https://www.youtube.com/oembed'));
    });
  });
}
