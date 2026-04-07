import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/provider_strategy.dart';
import 'package:flutter_embed/src/core/provider_strategies.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/provider_rule.dart';
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/services/api/meta_embed_api.dart';
import 'package:flutter_embed/src/services/api/reddit_embed_api.dart';
import 'package:flutter_embed/src/services/api/soundcloud_embed_api.dart';
import 'package:flutter_embed/src/services/api/spotify_embed_api.dart';
import 'package:flutter_embed/src/services/api/tiktok_embed_api.dart';
import 'package:flutter_embed/src/services/api/vimeo_embed_api.dart';
import 'package:flutter_embed/src/services/api/x_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MockWebViewController extends Mock implements WebViewController {}

void main() {
  group('Provider Strategies', () {
    late MockWebViewController mockController;

    setUp(() {
      mockController = MockWebViewController();
      registerFallbackValue(const JavaScriptMessage(message: ''));
    });

    const defaultContext = EmbedProviderContext(
      url: 'https://example.com',
      resolvedEndpoint: 'https://example.com/oembed',
      strategy: YouTubeProviderStrategy(),
      width: 640.0,
      locale: 'en',
      brightness: Brightness.light,
      facebookAppId: '',
      facebookClientToken: '',
    );

    test('YouTubeProviderStrategy', () async {
      const strategy = YouTubeProviderStrategy();
      expect(strategy.userAgent, contains('Chrome'));
      expect(strategy.resolveBaseUrl(null),
          equals('https://www.youtube-nocookie.com'));

      final api = strategy.createApi(defaultContext);
      expect(api.baseUrl, equals('https://www.youtube.com/oembed'));

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.pauseMedia(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);
    });

    test('TikTokProviderStrategy', () async {
      const strategy = TikTokProviderStrategy();
      expect(strategy.userAgent, contains('iPhone'));

      final api = strategy.createApi(defaultContext);
      expect(api, isA<TikTokEmbedApi>());

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.onPageFinished(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);

      await strategy.pauseMedia(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);
    });

    test('XProviderStrategy', () async {
      const strategy = XProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<XEmbedApi>());

      when(() => mockController.addJavaScriptChannel(any(),
              onMessageReceived: any(named: 'onMessageReceived')))
          .thenAnswer((_) async => {});
      await strategy.onWebViewCreated(mockController, onTwitterLoaded: () {});
      verify(() => mockController.addJavaScriptChannel(any(),
          onMessageReceived: any(named: 'onMessageReceived'))).called(1);

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.onPageFinished(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);
    });

    test('MetaProviderStrategy', () {
      const strategy = MetaProviderStrategy(EmbedType.instagram);
      final api = strategy.createApi(defaultContext);
      expect(api, isA<MetaEmbedApi>());
      expect((api as MetaEmbedApi).embedType, equals(EmbedType.instagram));
    });

    test('VimeoProviderStrategy', () async {
      const strategy = VimeoProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<VimeoEmbedApi>());

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.pauseMedia(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);
    });

    test('SoundCloudProviderStrategy', () async {
      const strategy = SoundCloudProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<SoundCloudEmbedApi>());

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.pauseMedia(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);
    });

    test('SpotifyProviderStrategy', () async {
      const strategy = SpotifyProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<SpotifyEmbedApi>());

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.pauseMedia(mockController);
      verify(() => mockController.runJavaScript(any())).called(1);
    });

    test('GenericEmbedProviderStrategy', () {
      const strategy = GenericEmbedProviderStrategy();
      expect(strategy.resolveBaseUrl(null), isNull);
      expect(strategy.resolveBaseUrl(EmbedData(html: '', providerUrl: 'https://example.com/')), equals('https://example.com'));
      expect(strategy.resolveBaseUrl(EmbedData(html: '', providerUrl: 'https://example.com')), equals('https://example.com'));

      final api = strategy.createApi(defaultContext);
      expect(api, isA<GenericEmbedApi>());
    });

    test('RedditProviderStrategy', () {
      const strategy = RedditProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<RedditEmbedApi>());
    });
  });
}
