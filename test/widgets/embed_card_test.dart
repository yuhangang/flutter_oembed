import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/models/tiktok_embed_params.dart';
import 'package:flutter_oembed/src/utils/embed_matchers.dart';
import 'package:flutter_oembed/src/widgets/embed_card.dart';
import 'package:flutter_oembed/src/widgets/embed_renderer.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void _stableOnLinkTap(String url, EmbedData? data) {}

class FakeWebViewPlatform extends WebViewPlatform {
  FakePlatformWebViewController? lastCreatedController;

  void reset() {
    lastCreatedController = null;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return FakePlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = FakePlatformWebViewController(params);
    lastCreatedController = controller;
    return controller;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakePlatformWebViewWidget(params);
  }
}

EmbedController buildController({
  SocialEmbedParam? param,
  EmbedConfig? config,
}) {
  final controller = EmbedController(config: config);
  if (param != null) {
    controller.synchronize(
      contentKey: param,
      config: config,
    );
  }
  return controller;
}

class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {}
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params) : super.implementation();

  String? lastLoadedHtml;
  String? lastBaseUrl;
  LoadRequestParams? lastRequest;

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    lastLoadedHtml = html;
    lastBaseUrl = baseUrl;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    lastRequest = params;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async => '0';

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}
}

class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  final fakePlatform = FakeWebViewPlatform();

  setUpAll(() {
    WebViewPlatform.instance = fakePlatform;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    fakePlatform.reset();
  });

  testWidgets('EmbedCard.url factory creates an EmbedCard with positional url',
      (
    tester,
  ) async {
    const testUrl = 'https://twitter.com/x/status/123';

    final widget = EmbedCard.url(
      testUrl,
      embedType: EmbedType.x,
    );

    expect(widget.url, testUrl);
    expect(widget.embedType, EmbedType.x);
  });

  testWidgets('EmbedCard.url factory allows null embedType', (tester) async {
    const testUrl = 'https://twitter.com/x/status/123';

    final widget = EmbedCard.url(testUrl);

    expect(widget.url, testUrl);
    expect(widget.embedType, isNull);
  });

  testWidgets('EmbedCard.url factory forwards controller', (tester) async {
    final controller = buildController(
      param: SocialEmbedParam(
        url: 'https://vimeo.com/22439234',
        embedType: EmbedType.vimeo,
      ),
    );

    try {
      final widget = EmbedCard.url(
        'https://vimeo.com/22439234',
        controller: controller,
      );

      expect(widget.controller, same(controller));
    } finally {
      controller.dispose();
    }
  });

  group('EmbedCard Auto-matching (via EmbedMatchers)', () {
    final samples = [
      {
        'url': 'https://www.youtube.com/watch?v=YSJY3DvnybE',
        'type': EmbedType.youtube,
        'source': 'YouTube',
      },
      {
        'url': 'https://www.dailymotion.com/video/x8q7p6v',
        'type': EmbedType.dailymotion,
        'source': 'Dailymotion',
      },
      {
        'url': 'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        'type': EmbedType.tiktok,
        'source': 'TikTok',
      },
      {
        'url': 'https://twitter.com/X/status/1328842765115920384',
        'type': EmbedType.x,
        'source': 'X',
      },
      {
        'url': 'https://www.instagram.com/p/DWPlkDrD7Jv/',
        'type': EmbedType.instagram,
        'source': 'Instagram',
      },
      {
        'url': 'https://www.threads.net/@zuck/post/Cx_M_y-L_y-',
        'type': EmbedType.threads,
        'source': 'Threads',
      },
      {
        'url': 'https://open.spotify.com/track/4JOEMgLkrHp8K1XNmyNffH',
        'type': EmbedType.spotify,
        'source': 'Spotify',
      },
      {
        'url':
            'https://www.reddit.com/r/flutterdev/comments/17yv8y8/how_to_implement_embed_in_flutter/',
        'type': EmbedType.reddit,
        'source': 'Reddit',
      },
      {
        'url': 'https://vimeo.com/22439234',
        'type': EmbedType.vimeo,
        'source': 'Vimeo',
      },
      {
        'url': 'https://x.com/NASA/status/2037551448439787917',
        'type': EmbedType.x,
        'source': 'X (with Video)',
      },
      {
        'url': 'https://soundcloud.com/maoli-music/i-aint-crazy',
        'type': EmbedType.soundcloud,
        'source': 'SoundCloud',
      },
      {
        'url':
            'https://giphy.com/gifs/moodman-monkey-side-eye-sideeye-H5C8CevNMbpBqNqFjl',
        'type': EmbedType.giphy,
        'source': 'GIPHY',
      },
    ];

    for (final sample in samples) {
      final url = sample['url'] as String;
      final expectedType = sample['type'] as EmbedType;
      final source = sample['source'] as String;

      test('auto-matches provider for $source', () {
        // Verify that the internal matching logic resolves it correctly
        expect(EmbedMatchers.getEmbedType(url), expectedType);
      });
    }
  });

  testWidgets('EmbedRenderer renders preloaded data without EmbedScope', (
    tester,
  ) async {
    final data = const EmbedData(
      html: '<div id="preloaded-renderer">renderer-html</div>',
      providerUrl: 'https://www.youtube.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmbedRenderer(
          data: data,
          embedType: EmbedType.youtube,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      fakePlatform.lastCreatedController?.lastLoadedHtml,
      contains('preloaded-renderer'),
    );
  });

  testWidgets('EmbedRenderer forwards embedConstraints to loader', (
    tester,
  ) async {
    const constraints = EmbedConstraints(
      preferredHeight: 232,
      minHeight: 180,
      maxHeight: 320,
    );
    final data = const EmbedData(
      html: '<div id="renderer-constraints">renderer-html</div>',
      providerUrl: 'https://www.youtube.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmbedRenderer(
          data: data,
          embedType: EmbedType.youtube,
          embedConstraints: constraints,
        ),
      ),
    );

    final loader =
        tester.widget<EmbedWidgetLoader>(find.byType(EmbedWidgetLoader));
    expect(loader.embedConstraints, equals(constraints));
  });

  testWidgets('EmbedCard preloadedData bypasses fetch path and loads HTML', (
    tester,
  ) async {
    final data = const EmbedData(
      html: '<div id="preloaded-card">card-html</div>',
      providerUrl: 'https://www.youtube.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmbedCard(
          url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          preloadedData: data,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      fakePlatform.lastCreatedController?.lastLoadedHtml,
      contains('preloaded-card'),
    );
  });

  testWidgets('EmbedCard reloads preloaded WebView when widget inputs change', (
    tester,
  ) async {
    const firstUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const secondUrl = 'https://www.youtube.com/watch?v=9bZkp7q19f0';

    final firstData = const EmbedData(
      html: '<div id="first-preloaded">first</div>',
      providerUrl: 'https://www.youtube.com',
    );
    final secondData = const EmbedData(
      html: '<div id="second-preloaded">second</div>',
      providerUrl: 'https://www.youtube.com',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmbedCard(
          url: firstUrl,
          preloadedData: firstData,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      fakePlatform.lastCreatedController?.lastLoadedHtml,
      contains('first-preloaded'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EmbedCard(
          url: secondUrl,
          preloadedData: secondData,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      fakePlatform.lastCreatedController?.lastLoadedHtml,
      contains('second-preloaded'),
    );
  });

  testWidgets(
      'embed params updates refresh the webview and external controller even with scope cache',
      (tester) async {
    final controller = buildController(
      param: SocialEmbedParam(
        url: 'https://www.tiktok.com/@user/video/123',
        embedType: EmbedType.tiktok_v1,
      ),
    );
    final config = const EmbedConfig(cache: EmbedCacheConfig(enabled: true));

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: config,
            child: EmbedCard(
              url: 'https://www.tiktok.com/@user/video/123',
              embedType: EmbedType.tiktok_v1,
              controller: controller,
              embedParams: const TikTokEmbedParams(
                autoplay: false,
                controls: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        fakePlatform.lastCreatedController?.lastLoadedHtml,
        contains('autoplay=0'),
      );
      expect(
        tester
            .widget<EmbedWebView>(find.byType(EmbedWebView))
            .param
            .embedParams,
        const TikTokEmbedParams(
          autoplay: false,
          controls: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: config,
            child: EmbedCard(
              url: 'https://www.tiktok.com/@user/video/123',
              embedType: EmbedType.tiktok_v1,
              controller: controller,
              embedParams: const TikTokEmbedParams(
                autoplay: true,
                controls: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        fakePlatform.lastCreatedController?.lastLoadedHtml,
        contains('autoplay=1'),
      );
      expect(
        fakePlatform.lastCreatedController?.lastLoadedHtml,
        contains('controls=0'),
      );
      expect(
        tester
            .widget<EmbedWebView>(find.byType(EmbedWebView))
            .param
            .embedParams,
        const TikTokEmbedParams(
          autoplay: true,
          controls: false,
        ),
      );
      expect(controller.loadingState, EmbedLoadingState.loading);
    } finally {
      controller.dispose();
    }
  });

  testWidgets('EmbedCard.url factory and overrides', (tester) async {
    const style = EmbedStyle(maxScrollableHeight: 400);
    const cache = EmbedCacheConfig(enabled: false);
    const embedConstraints = EmbedConstraints(preferredHeight: 232);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmbedCard.url(
            'https://youtube.com/watch?v=123',
            style: style,
            scrollable: true,
            cacheConfig: cache,
            embedConstraints: embedConstraints,
          ),
        ),
      ),
    );

    final loader =
        tester.widget<EmbedWidgetLoader>(find.byType(EmbedWidgetLoader));
    expect(loader.style, equals(style));
    expect(loader.scrollable, isTrue);
    expect(loader.cacheConfig, equals(cache));
    expect(loader.embedConstraints, equals(embedConstraints));
  });

  testWidgets('legacy embedHeight maps to preferredHeight constraint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmbedCard.url(
            'https://youtube.com/watch?v=123',
            embedHeight: 232,
          ),
        ),
      ),
    );

    final loader =
        tester.widget<EmbedWidgetLoader>(find.byType(EmbedWidgetLoader));
    expect(
      loader.embedConstraints,
      equals(const EmbedConstraints(preferredHeight: 232)),
    );
  });

  testWidgets(
      'rebuild with the same onLinkTap callback preserves the loader controller',
      (tester) async {
    final data = const EmbedData(
      html: '<div id="stable-callback">stable</div>',
      providerUrl: 'https://www.youtube.com',
    );

    Widget buildCard() {
      return MaterialApp(
        home: EmbedScope(
          config: const EmbedConfig(),
          child: EmbedCard(
            url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            preloadedData: data,
            onLinkTap: _stableOnLinkTap,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildCard());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final firstController =
        tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

    await tester.pumpWidget(buildCard());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final secondController =
        tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

    expect(secondController, same(firstController));
  });
}
