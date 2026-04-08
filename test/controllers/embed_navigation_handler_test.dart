import 'package:flutter_oembed/src/controllers/embed_navigation_handler.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../fake_webview_platform.dart';

class MockNavigationRequest extends Mock implements NavigationRequest {}

class MockWebResourceError extends Mock implements WebResourceError {}

class MockHttpResponseError extends Mock implements HttpResponseError {}

void main() {
  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('EmbedNavigationHandler', () {
    late SocialEmbedParam param;
    late EmbedConfig config;

    setUp(() {
      param = SocialEmbedParam(
        url: 'https://twitter.com/user/status/123',
        embedType: EmbedType.x,
      );
      config = const EmbedConfig();
    });

    group('buildDelegate()', () {
      test('should correctly set all callbacks in the NavigationDelegate', () {
        bool pageStarted = false;
        bool pageFinished = false;
        bool webResourceError = false;

        final handler = EmbedNavigationHandler(param: param, config: config);
        final delegate = handler.buildDelegate(
          baseUrl: 'https://twitter.com',
          loadingStateGetter: () => EmbedLoadingState.loaded,
          onPageStarted: (url) => pageStarted = true,
          onPageFinished: () async => pageFinished = true,
          onWebResourceError: (error) => webResourceError = true,
        );

        expect(delegate.onPageStarted, isNotNull);
        expect(delegate.onPageFinished, isNotNull);
        expect(delegate.onWebResourceError, isNotNull);

        // Trigger them manually to get coverage
        delegate.onPageStarted!('https://twitter.com');
        expect(pageStarted, isTrue);

        delegate.onPageFinished!('https://twitter.com');
        expect(pageFinished, isTrue);

        final error = MockWebResourceError();
        when(() => error.errorCode).thenReturn(-1);
        when(() => error.description).thenReturn('Error');
        when(() => error.isForMainFrame).thenReturn(true);

        delegate.onWebResourceError!(error);
        expect(webResourceError, isTrue);
      });
    });

    group('onNavigationRequest()', () {
      test('should allow navigation to about:blank', () async {
        final handler = EmbedNavigationHandler(param: param, config: config);
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('about:blank');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.navigate);
      });

      test('should use param URL for TikTok navigation requests', () async {
        String? tappedUrl;
        final tikTokParam = SocialEmbedParam(
            url: 'https://tiktok.com/123', embedType: EmbedType.tiktok);
        config = EmbedConfig(onLinkTap: (url, _) => tappedUrl = url);

        final handler =
            EmbedNavigationHandler(param: tikTokParam, config: config);
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://tiktok.com',
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        await delegate.onNavigationRequest!(request);
        expect(tappedUrl, equals('https://tiktok.com/123'));
      });

      test('should prevent navigation when onLinkTap is not configured',
          () async {
        final handler = EmbedNavigationHandler(param: param, config: config);
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
      });

      test('should prevent navigation when onNavigationRequest returns null',
          () async {
        config = EmbedConfig(onNavigationRequest: (req) => null);
        final handler = EmbedNavigationHandler(param: param, config: config);
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
      });

      test('should prevent navigation when the widget is not visible',
          () async {
        final handler = EmbedNavigationHandler(param: param, config: config);
        handler.isVisible = false;
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
      });

      test('should prevent navigation to the base URL itself', () async {
        final handler = EmbedNavigationHandler(param: param, config: config);
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://twitter.com/');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
      });

      test('should call onLinkTap and prevent navigation for external links',
          () async {
        String? tappedUrl;
        final config = EmbedConfig(onLinkTap: (url, _) => tappedUrl = url);
        final handler = EmbedNavigationHandler(param: param, config: config);
        handler.isVisible = true;

        final delegate = handler.buildDelegate(
          baseUrl: 'https://twitter.com',
          loadingStateGetter: () => EmbedLoadingState.loaded,
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(tappedUrl, 'https://google.com');
      });
    });

    group('onWebResourceError()', () {
      test('should handle web resource errors and log them', () {
        final handler =
            EmbedNavigationHandler(param: param, config: const EmbedConfig());
        final delegate = handler.buildDelegate(
          baseUrl: 'https://twitter.com',
          loadingStateGetter: () => EmbedLoadingState.loaded,
          onPageFinished: () async {},
        );

        final error = MockWebResourceError();
        when(() => error.errorCode).thenReturn(-1);
        when(() => error.description).thenReturn('Error');
        when(() => error.errorType).thenReturn(WebResourceErrorType.hostLookup);
        when(() => error.isForMainFrame).thenReturn(true);

        delegate.onWebResourceError!(error);
      });
    });
  });
}
