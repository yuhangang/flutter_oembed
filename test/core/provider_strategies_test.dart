import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/core/provider_strategies.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_renderer.dart';
import 'package:flutter_oembed/src/models/provider_rule.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/services/api/meta_embed_api.dart';
import 'package:flutter_oembed/src/services/api/reddit_embed_api.dart';
import 'package:flutter_oembed/src/services/api/soundcloud_embed_api.dart';
import 'package:flutter_oembed/src/services/api/spotify_embed_api.dart';
import 'package:flutter_oembed/src/services/api/tiktok_embed_api.dart';
import 'package:flutter_oembed/src/services/api/vimeo_embed_api.dart';
import 'package:flutter_oembed/src/services/api/x_embed_api.dart';
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
      providerName: 'YouTube',
    );

    test('YouTubeProviderStrategy', () async {
      const strategy = YouTubeProviderStrategy();
      expect(strategy.userAgent, contains('Chrome'));
      expect(strategy.resolveBaseUrl(null),
          equals('https://www.youtube-nocookie.com'));

      final api = strategy.createApi(defaultContext);
      expect(api.baseUrl, equals('https://www.youtube.com/oembed'));

      final scripts = <String>[];
      when(() => mockController.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });
      await strategy.pauseMedia(mockController);
      await strategy.resumeMedia(mockController);
      await strategy.muteMedia(mockController);
      await strategy.unmuteMedia(mockController);

      expect(scripts, hasLength(8));
      expect(scripts[1], contains('youtube-nocookie.com'));
      expect(scripts[1], contains('pauseVideo'));
      expect(scripts[3], contains('playVideo'));
      expect(scripts[5], contains('"func":"mute"'));
      expect(scripts[7], contains('"func":"unMute"'));
    });

    test('TikTokProviderStrategy', () async {
      const strategy = TikTokProviderStrategy();
      expect(strategy.userAgent, contains('iPhone'));

      final api = strategy.createApi(defaultContext);
      expect(api, isA<TikTokEmbedApi>());

      final scripts = <String>[];
      when(() => mockController.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });
      await strategy.onPageFinished(mockController);
      expect(scripts, hasLength(2));

      clearInteractions(mockController);
      scripts.clear();
      await strategy.pauseMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"pause"'));

      scripts.clear();
      await strategy.resumeMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"play"'));

      scripts.clear();
      await strategy.muteMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"mute"'));

      scripts.clear();
      await strategy.unmuteMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"unMute"'));

      scripts.clear();
      await strategy.seekMediaTo(mockController, const Duration(seconds: 15));
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"seekTo"'));
      expect(scripts[1], contains('"value":15'));

      // Verify renderer resolution
      final renderer = strategy.resolveRenderer(defaultContext);
      expect(renderer, isA<OEmbedRenderer>());
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

      final scripts = <String>[];
      when(() => mockController.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });
      await strategy.pauseMedia(mockController);
      await strategy.resumeMedia(mockController);
      await strategy.muteMedia(mockController);
      await strategy.unmuteMedia(mockController);

      expect(scripts, hasLength(8));
      expect(scripts[1], contains('"method":"pause"'));
      expect(scripts[3], contains('"method":"play"'));
      expect(scripts[5], contains('"value":0'));
      expect(scripts[7], contains('"value":1'));
    });

    test('SoundCloudProviderStrategy', () async {
      const strategy = SoundCloudProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<SoundCloudEmbedApi>());

      final scripts = <String>[];
      when(() => mockController.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });
      await strategy.pauseMedia(mockController);
      await strategy.resumeMedia(mockController);

      expect(scripts, hasLength(4));
      expect(scripts[1], contains('"method":"pause"'));
      expect(scripts[3], contains('"method":"play"'));
    });

    test('SpotifyProviderStrategy', () async {
      const strategy = SpotifyProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<SpotifyEmbedApi>());

      final scripts = <String>[];
      when(() => mockController.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });
      await strategy.pauseMedia(mockController);
      await strategy.resumeMedia(mockController);

      expect(scripts, hasLength(4));
      expect(scripts[1], contains('"command":"pause"'));
      expect(scripts[3], contains('"command":"play"'));
    });

    test('DailymotionProviderStrategy', () async {
      const strategy = DailymotionProviderStrategy();
      final api = strategy.createApi(defaultContext);
      expect(api, isA<GenericEmbedApi>());

      final scripts = <String>[];
      when(() => mockController.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });
      await strategy.pauseMedia(mockController);
      await strategy.resumeMedia(mockController);
      await strategy.muteMedia(mockController);
      await strategy.unmuteMedia(mockController);

      expect(scripts, hasLength(8));
      expect(scripts[1], contains('"command":"pause"'));
      expect(scripts[3], contains('"command":"play"'));
      expect(scripts[5], contains('"parameters":[true]'));
      expect(scripts[7], contains('"parameters":[false]'));
    });

    test('GenericEmbedProviderStrategy', () {
      const strategy = GenericEmbedProviderStrategy();
      expect(strategy.resolveBaseUrl(null), isNull);
      expect(
          strategy.resolveBaseUrl(
              const EmbedData(html: '', providerUrl: 'https://example.com/')),
          equals('https://example.com'));
      expect(
          strategy.resolveBaseUrl(
              const EmbedData(html: '', providerUrl: 'https://example.com')),
          equals('https://example.com'));

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
