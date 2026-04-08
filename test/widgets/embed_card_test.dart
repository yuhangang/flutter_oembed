import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/utils/embed_matchers.dart';
import 'package:flutter_oembed/src/widgets/embed_card.dart';
import 'package:flutter_oembed/src/widgets/embed_renderer.dart';
import 'package:flutter_oembed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

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

  testWidgets('EmbedCard.url factory and overrides', (tester) async {
    const style = EmbedStyle(maxScrollableHeight: 400);
    const cache = EmbedCacheConfig(enabled: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmbedCard.url(
            'https://youtube.com/watch?v=123',
            style: style,
            scrollable: true,
            cacheConfig: cache,
          ),
        ),
      ),
    );

    final loader =
        tester.widget<EmbedWidgetLoader>(find.byType(EmbedWidgetLoader));
    expect(loader.style, equals(style));
    expect(loader.scrollable, isTrue);
    expect(loader.cacheConfig, equals(cache));
  });
}
