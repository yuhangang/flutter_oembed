import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/core/provider_strategies.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_renderer.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
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

const _testRule = EmbedProviderRule(
  pattern: r'https?://example\.com/.*',
  endpoint: 'https://example.com/oembed',
  providerName: 'Example',
);

EmbedWebViewDriver buildDriver(
  WebViewController controller, {
  SocialEmbedParam? param,
}) {
  final embedParam = param ??
      SocialEmbedParam(
        url: 'https://example.com',
        embedType: EmbedType.other,
      );
  final embedController = EmbedController()
    ..synchronize(
      contentKey: embedParam,
    );
  return EmbedWebViewDriver(
    controller: embedController,
    param: embedParam,
    webViewController: controller,
  );
}

void main() {
  group('Provider Strategies', () {
    late MockWebViewController mockController;

    setUp(() {
      mockController = MockWebViewController();
      registerFallbackValue(const JavaScriptMessage(message: ''));
      when(() => mockController.currentUrl())
          .thenAnswer((_) async => 'https://example.com');
      when(() => mockController.runJavaScriptReturningResult(any()))
          .thenAnswer((_) async => '300');
    });

    const defaultContext = EmbedProviderContext(
      url: 'https://example.com',
      resolvedEndpoint: 'https://example.com/oembed',
      rule: _testRule,
      strategy: YouTubeProviderStrategy(),
      width: 640.0,
      locale: 'en',
      brightness: Brightness.light,
      facebookAppId: null,
      facebookClientToken: null,
      providerName: 'YouTube',
      variant: EmbedVariant.standard,
      capabilities: EmbedProviderCapabilities(),
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
      await strategy.mediaStrategy!.pauseMedia(mockController);
      await strategy.mediaStrategy!.resumeMedia(mockController);
      await strategy.mediaStrategy!.muteMedia(mockController);
      await strategy.mediaStrategy!.unmuteMedia(mockController);

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
      await strategy.onPageFinished(buildDriver(mockController));
      expect(scripts, hasLength(1));
      expect(
        scripts.single,
        contains("document.querySelectorAll('video, audio')"),
      );

      clearInteractions(mockController);
      scripts.clear();
      await strategy.mediaStrategy!.pauseMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('window.postMessage'));
      expect(scripts[1], contains('"type":"pause"'));

      scripts.clear();
      await strategy.mediaStrategy!.resumeMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"play"'));

      scripts.clear();
      await strategy.mediaStrategy!.muteMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"mute"'));

      scripts.clear();
      await strategy.mediaStrategy!.unmuteMedia(mockController);
      expect(scripts, hasLength(2));
      expect(scripts[1], contains('"type":"unMute"'));

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
      await strategy.onWebViewCreated(buildDriver(
        mockController,
        param: SocialEmbedParam(
          url: 'https://twitter.com/user/status/1',
          embedType: EmbedType.x,
        ),
      ));
      verify(() => mockController.addJavaScriptChannel(any(),
          onMessageReceived: any(named: 'onMessageReceived'))).called(1);

      when(() => mockController.runJavaScript(any()))
          .thenAnswer((_) async => {});
      await strategy.onPageFinished(buildDriver(
        mockController,
        param: SocialEmbedParam(
          url: 'https://twitter.com/user/status/1',
          embedType: EmbedType.x,
        ),
      ));
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
      await strategy.mediaStrategy!.pauseMedia(mockController);
      await strategy.mediaStrategy!.resumeMedia(mockController);
      await strategy.mediaStrategy!.muteMedia(mockController);
      await strategy.mediaStrategy!.unmuteMedia(mockController);

      expect(scripts, hasLength(8));
      expect(scripts[1], contains('window.postMessage'));
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
      await strategy.mediaStrategy!.pauseMedia(mockController);
      await strategy.mediaStrategy!.resumeMedia(mockController);

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
      await strategy.mediaStrategy!.pauseMedia(mockController);
      await strategy.mediaStrategy!.resumeMedia(mockController);

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
      await strategy.mediaStrategy!.pauseMedia(mockController);
      await strategy.mediaStrategy!.resumeMedia(mockController);
      await strategy.mediaStrategy!.muteMedia(mockController);
      await strategy.mediaStrategy!.unmuteMedia(mockController);

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
