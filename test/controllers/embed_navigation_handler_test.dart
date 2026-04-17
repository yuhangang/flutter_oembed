import 'package:flutter_oembed/src/controllers/embed_navigation_handler.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';

class MockNavigationRequest extends Mock implements NavigationRequest {}

class MockWebResourceError extends Mock implements WebResourceError {}

class MockHttpResponseError extends Mock implements HttpResponseError {}

class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<LaunchCall> launchedUrls = <LaunchCall>[];
  bool shouldSucceed = true;
  Object? launchError;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    if (launchError != null) {
      throw launchError!;
    }

    launchedUrls.add(
      LaunchCall(
        url: url,
        useSafariVC: useSafariVC,
        useWebView: useWebView,
        universalLinksOnly: universalLinksOnly,
      ),
    );

    return shouldSucceed;
  }
}

class LaunchCall {
  final String url;
  final bool useSafariVC;
  final bool useWebView;
  final bool universalLinksOnly;

  const LaunchCall({
    required this.url,
    required this.useSafariVC,
    required this.useWebView,
    required this.universalLinksOnly,
  });
}

const _tikTokRule = EmbedProviderRule(
  pattern: r'https?://(?:www\.)?tiktok\.com/.*',
  endpoint: 'https://www.tiktok.com/oembed',
  providerName: 'TikTok',
  capabilities: EmbedProviderCapabilities(
    isVideo: true,
    useOriginalContentUrlForCallback: true,
  ),
);

void main() {
  late UrlLauncherPlatform originalUrlLauncher;
  late FakeUrlLauncherPlatform fakeUrlLauncher;
  late DateTime now;

  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
    originalUrlLauncher = UrlLauncherPlatform.instance;
  });

  tearDownAll(() {
    UrlLauncherPlatform.instance = originalUrlLauncher;
  });

  group('EmbedNavigationHandler', () {
    late SocialEmbedParam param;
    late EmbedConfig config;

    setUp(() {
      now = DateTime(2026, 4, 14, 12);
      fakeUrlLauncher = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakeUrlLauncher;
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

        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
        );
        final delegate = handler.buildDelegate(
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
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
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
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

        final handler = EmbedNavigationHandler(
          param: tikTokParam,
          config: config,
          providerRuleGetter: () => _tikTokRule,
          now: () => now,
        );

        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://tiktok.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('https://example.com/deep-link');

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        await delegate.onNavigationRequest!(request);
        expect(tappedUrl, equals('https://tiktok.com/123'));
      });

      test('should allow sub-frame navigation', () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(false);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.navigate);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test('should allow trusted main-frame startup navigation while loading',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loading,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const ['https://platform.twitter.com/embed'],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url)
            .thenReturn('https://platform.twitter.com/embed');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.navigate);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test('should allow same-provider host redirects while loading', () async {
        final youtubeParam = SocialEmbedParam(
          url: 'https://www.youtube.com/watch?v=123',
          embedType: EmbedType.youtube,
        );
        final handler = EmbedNavigationHandler(
          param: youtubeParam,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loading,
          baseUrl: 'https://www.youtube.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://m.youtube.com/watch?v=123');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.navigate);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test('should allow provider-specific cross-host redirects while loading',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loading,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://twitter.com/');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.navigate);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test('should block unexpected main-frame redirects while loading',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loading,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test(
          'should fall back to the default policy when onNavigationRequest returns null',
          () async {
        config = EmbedConfig(onNavigationRequest: (req) => null);
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('https://google.com');

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls.single.url, 'https://google.com');
      });

      test('should prevent navigation when the widget is not visible',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        handler.isVisible = false;
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('https://google.com');

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test(
          'should call onLinkTap and prevent navigation for user-initiated external links',
          () async {
        String? tappedUrl;
        final config = EmbedConfig(onLinkTap: (url, _) => tappedUrl = url);
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        handler.isVisible = true;

        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('https://google.com/path');

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(tappedUrl, 'https://google.com/path');
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test(
          'should block external http links when there is no recent user intent',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test(
          'should launch the captured click target for user-initiated external http links',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('https://google.com/path');

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(
            fakeUrlLauncher.launchedUrls.single.url, 'https://google.com/path');
        expect(fakeUrlLauncher.launchedUrls.single.useWebView, isFalse);
      });

      test(
          'should launch the requested URL for recent generic user interaction',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserInteraction();

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls.single.url, 'https://google.com');
        expect(fakeUrlLauncher.launchedUrls.single.useWebView, isFalse);
      });

      test(
          'should block external custom schemes when there is no recent user intent',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('twitter://status?id=123');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test(
          'should launch user-initiated custom schemes instead of letting WebView crash',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('twitter://status?id=123');

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('twitter://status?id=123');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(
          fakeUrlLauncher.launchedUrls.single.url,
          'twitter://status?id=123',
        );
      });

      test('should ignore expired user intent for external navigation',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserNavigationIntent('https://google.com');
        now = now.add(const Duration(seconds: 2));

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });

      test('should ignore expired generic user interaction for navigation',
          () async {
        final handler = EmbedNavigationHandler(
          param: param,
          config: config,
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          loadingStateGetter: () => EmbedLoadingState.loaded,
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
          onPageFinished: () async {},
        );
        handler.recordUserInteraction();
        now = now.add(const Duration(seconds: 2));

        final request = MockNavigationRequest();
        when(() => request.url).thenReturn('https://google.com');
        when(() => request.isMainFrame).thenReturn(true);

        final decision = await delegate.onNavigationRequest!(request);
        expect(decision, NavigationDecision.prevent);
        expect(fakeUrlLauncher.launchedUrls, isEmpty);
      });
    });

    group('onWebResourceError()', () {
      test('should handle web resource errors and log them', () {
        final handler = EmbedNavigationHandler(
          param: param,
          config: const EmbedConfig(),
          providerRuleGetter: () => null,
          now: () => now,
        );
        final delegate = handler.buildDelegate(
          baseUrl: 'https://twitter.com',
          trustedMainFrameUrls: const [],
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
