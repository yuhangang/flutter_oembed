import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_tracking.dart';

class MockWebViewController extends Mock implements WebViewController {}

class MockWebViewPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements WebViewPlatform {}

class MockPlatformNavigationDelegate extends Mock
    with MockPlatformInterfaceMixin
    implements PlatformNavigationDelegate {}

class FakeNavigationDelegate extends Fake implements NavigationDelegate {}

class FakePlatformNavigationDelegateCreationParams extends Fake
    implements PlatformNavigationDelegateCreationParams {}

void main() {
  late MockWebViewController mockWebViewController;
  late MockPlatformNavigationDelegate mockPlatformNavigationDelegate;
  late SocialEmbedParam testParam;

  setUpAll(() {
    final mockPlatform = MockWebViewPlatform();
    WebViewPlatform.instance = mockPlatform;

    registerFallbackValue(FakePlatformNavigationDelegateCreationParams());

    mockPlatformNavigationDelegate = MockPlatformNavigationDelegate();
    when(() => mockPlatform.createPlatformNavigationDelegate(any()))
        .thenReturn(mockPlatformNavigationDelegate);

    when(() => mockPlatformNavigationDelegate.setOnNavigationRequest(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatformNavigationDelegate.setOnPageStarted(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatformNavigationDelegate.setOnPageFinished(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatformNavigationDelegate.setOnWebResourceError(any()))
        .thenAnswer((_) async {});
    when(() => mockPlatformNavigationDelegate.setOnUrlChange(any()))
        .thenAnswer((_) async {});

    registerFallbackValue(const Color(0xFFFFFFFF));
    registerFallbackValue(JavaScriptMode.unrestricted);
    registerFallbackValue(Uri.parse('about:blank'));
    registerFallbackValue(LoadRequestMethod.get);
    registerFallbackValue(FakeNavigationDelegate());
  });

  setUp(() {
    mockWebViewController = MockWebViewController();
    testParam = SocialEmbedParam(
      url: 'https://twitter.com/user/status/12345',
      tracking: const EmbedTracking(
        source: 'test',
        contentId: '12345',
        pageIdentifier: 'test-page',
        elementId: 'element-1',
      ),
    );

    // Default stubs
    when(() => mockWebViewController.setBackgroundColor(any()))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.setJavaScriptMode(any()))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.enableZoom(any()))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.setNavigationDelegate(any()))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.loadRequest(
          any(),
          headers: any(named: 'headers'),
          method: any(named: 'method'),
          body: any(named: 'body'),
        )).thenAnswer((_) async {});
    when(() => mockWebViewController.loadHtmlString(any(),
        baseUrl: any(named: 'baseUrl'))).thenAnswer((_) async {});
    when(() => mockWebViewController.addJavaScriptChannel(any(),
            onMessageReceived: any(named: 'onMessageReceived')))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.setUserAgent(any()))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.runJavaScript(any()))
        .thenAnswer((_) async {});
    when(() => mockWebViewController.runJavaScriptReturningResult(any()))
        .thenAnswer((_) async => '0');
    when(() => mockWebViewController.reload()).thenAnswer((_) async {});
  });

  group('EmbedController', () {
    test('initial state is loading', () {
      final controller = EmbedController(param: testParam);
      expect(controller.loadingState, EmbedLoadingState.loading);
      expect(controller.height, isNull);
      expect(controller.isVisible, isTrue);
    });

    test('setHeight updates height and notifies listeners', () {
      final controller = EmbedController(param: testParam);
      bool listenerCalled = false;
      controller.addListener(() => listenerCalled = true);

      controller.setHeight(100.0);
      expect(controller.height, 100.0);
      expect(listenerCalled, isTrue);
    });

    test('setLoadingState updates state and notifies listeners', () {
      final controller = EmbedController(param: testParam);
      bool listenerCalled = false;
      controller.addListener(() => listenerCalled = true);

      controller.setLoadingState(EmbedLoadingState.loaded);
      expect(controller.loadingState, EmbedLoadingState.loaded);
      expect(listenerCalled, isTrue);
    });

    test('updateVisibility updates visibility and calls callback', () {
      final controller = EmbedController(param: testParam);
      bool callbackCalledWith = true;

      controller.updateVisibility(false, onVisibilityChange: (visible) {
        callbackCalledWith = visible;
      });

      expect(controller.isVisible, isFalse);
      expect(callbackCalledWith, isFalse);
    });

    test('disposed controller ignores state mutations', () {
      final controller = EmbedController(param: testParam);
      controller.dispose();

      controller.setHeight(500);
      expect(controller.height, isNull);

      controller.setLoadingState(EmbedLoadingState.loaded);
      expect(controller.loadingState, EmbedLoadingState.loading);

      controller.updateVisibility(false, onVisibilityChange: (_) {});
      expect(controller.isVisible, isTrue);

      controller.setDidRetry();
      expect(controller.didRetry, isFalse);
    });

    test('timeout timer triggers error state', () {
      fakeAsync((async) {
        final controller = EmbedController(param: testParam);

        controller.startLoadTimeout();
        expect(controller.loadingState, EmbedLoadingState.loading);

        async.elapse(const Duration(seconds: 11));
        expect(controller.loadingState, EmbedLoadingState.error);
      });
    });
  });

  group('EmbedWebViewDriver', () {
    test('initEmbedWebview configures webViewController correctly', () async {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.red,
        embedData: null,
        embedUrl: 'https://example.com/embed',
        maxWidth: 500,
      );

      verify(() => mockWebViewController.setBackgroundColor(Colors.red))
          .called(1);
      verify(() => mockWebViewController
          .setJavaScriptMode(JavaScriptMode.unrestricted)).called(1);
      verify(() => mockWebViewController.loadRequest(
            Uri.parse('https://example.com/embed'),
            headers: const <String, String>{},
            method: LoadRequestMethod.get,
            body: null,
          )).called(1);
    });

    test('initEmbedWebview sends referer headers for YouTube iframe loads',
        () async {
      final youtubeParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: 'dQw4w9WgXcQ',
          pageIdentifier: 'page',
          elementId: 'el',
        ),
        embedType: EmbedType.youtube,
      );
      final controller = EmbedController(param: youtubeParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://www.youtube.com/embed/dQw4w9WgXcQ?playsinline=1',
        maxWidth: 400,
      );

      verify(() => mockWebViewController.loadRequest(
            Uri.parse(
              'https://www.youtube.com/embed/dQw4w9WgXcQ?playsinline=1',
            ),
            headers: const <String, String>{
              'Referer': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            },
            method: LoadRequestMethod.get,
            body: null,
          )).called(1);
    });

    test('dispose cleans up timers and webViewController', () async {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      driver.dispose();

      verify(() => mockWebViewController.loadRequest(
            Uri.parse('about:blank'),
            headers: const <String, String>{},
            method: LoadRequestMethod.get,
            body: null,
          )).called(1);
      verify(() => mockWebViewController.setNavigationDelegate(any()))
          .called(1);
    });

    test('initEmbedWebview handles TikTok correctly', () async {
      final tiktokParam = SocialEmbedParam(
        url: 'https://www.tiktok.com/@user/video/12345',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: '12345',
          pageIdentifier: 'test-page',
          elementId: 'element-1',
        ),
      );
      final controller = EmbedController(param: tiktokParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://www.tiktok.com/embed/12345',
        maxWidth: 400,
      );

      verify(() => mockWebViewController.setUserAgent(any())).called(1);
    });

    test('initEmbedWebview handles Twitter/X correctly', () async {
      final xParam = SocialEmbedParam(
        url: 'https://twitter.com/user/status/12345',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: '12345',
          pageIdentifier: 'test-page',
          elementId: 'element-1',
        ),
      );
      final controller = EmbedController(param: xParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://twitter.com/user/status/12345',
        maxWidth: 400,
      );

      verify(() => mockWebViewController.addJavaScriptChannel('OnTwitterLoaded',
          onMessageReceived: any(named: 'onMessageReceived'))).called(1);
    });

    test('loadHtmlString uses correct baseUrl for Meta providers', () async {
      final fbParam = SocialEmbedParam(
        url: 'https://www.facebook.com/post/1',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: '1',
          pageIdentifier: 'page',
          elementId: 'el',
        ),
      );
      final controller = EmbedController(param: fbParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );
      final embedData = EmbedData(
        providerUrl: 'https://www.facebook.com',
        html: '<div>code</div>',
        title: 'title',
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: embedData,
        embedUrl: null,
        maxWidth: 400,
      );

      verify(() => mockWebViewController.loadHtmlString(any(),
          baseUrl: 'https://www.facebook.com')).called(1);
    });

    test('pauseMedias handles TikTok photo vs videos', () async {
      final photoParam = SocialEmbedParam(
        url: 'https://www.tiktok.com/@user/photo/123',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: '123',
          pageIdentifier: 'page',
          elementId: 'el',
        ),
        embedType: EmbedType.tiktok,
      );
      final controller = EmbedController(param: photoParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.pauseMedias();
      verify(() => mockWebViewController.runJavaScript(any()))
          .called(1); // mute script

      final videoParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=123',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: '123',
          pageIdentifier: 'page',
          elementId: 'el',
        ),
      );
      final videoController = EmbedController(param: videoParam);
      final videoDriver = EmbedWebViewDriver(
        controller: videoController,
        webViewController: mockWebViewController,
      );

      await videoDriver.pauseMedias();
      verify(() => mockWebViewController.runJavaScript(any()))
          .called(greaterThan(0));
    });

    test('updateEmbedPostHeight success handles new height', () async {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );
      when(() => mockWebViewController.runJavaScriptReturningResult(any()))
          .thenAnswer((_) async => '500');

      await driver.updateEmbedPostHeight();
      expect(controller.height, 500.0);
    });

    test('refresh reloads and resets state', () {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      driver.refresh();
      verify(() => mockWebViewController.reload()).called(1);
    });

    test('initEmbedWebview returns early if already loaded', () async {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );
      controller.setLoadingState(EmbedLoadingState.loaded);
      controller.setHeight(500);

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'url',
        maxWidth: 400,
      );

      verifyNever(() => mockWebViewController.setBackgroundColor(any()));
    });

    test('HeightChannel updates height correctly', () async {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'url',
        maxWidth: 400,
      );

      controller.setLoadingState(EmbedLoadingState.loaded);

      // Capture the JavaScriptChannel callback
      final captureChannel =
          verify(() => mockWebViewController.addJavaScriptChannel(
                'HeightChannel',
                onMessageReceived: captureAny(named: 'onMessageReceived'),
              )).captured.last as void Function(JavaScriptMessage);

      captureChannel(const JavaScriptMessage(message: '600'));
      expect(controller.height, 600.0);
    });

    test('updateEmbedPostHeight handles errors gracefully', () async {
      final controller = EmbedController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );
      when(() => mockWebViewController.runJavaScriptReturningResult(any()))
          .thenThrow(Exception('JS error'));

      // Should not throw
      await driver.updateEmbedPostHeight();
    });

    test('onPageFinished with fake_async sequence', () {
      fakeAsync((async) {
        // Use a non-Twitter/non-TikTok URL to test the direct _handleEmbedPageFinished flow
        final generalParam = SocialEmbedParam(
          url: 'https://www.youtube.com/watch?v=1',
          tracking: const EmbedTracking(
            source: 'test',
            contentId: '1',
            pageIdentifier: 'p',
            elementId: 'e',
          ),
          embedType: EmbedType.youtube,
        );
        final controller = EmbedController(param: generalParam);
        final driver = EmbedWebViewDriver(
          controller: controller,
          webViewController: mockWebViewController,
        );

        driver.initEmbedWebview(
          backgroundColor: Colors.white,
          embedData: null,
          embedUrl: 'url',
          maxWidth: 400,
        );
        async.flushMicrotasks();

        // Capture onPageFinished AFTER init has settled
        final capturedOnPageFinished =
            verify(() => mockPlatformNavigationDelegate.setOnPageFinished(
                  captureAny(),
                )).captured.last as void Function(String);

        // Set up sequential return values for height checks
        final heightRes = [300, 350];
        int count = 0;
        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenAnswer((_) async => heightRes[count++ % heightRes.length]);

        // Verify we are still in loading state
        expect(controller.loadingState, EmbedLoadingState.loading);

        // Trigger onPageFinished
        capturedOnPageFinished('https://example.com');

        // Wait for first update (300ms delay + update)
        async.elapse(const Duration(milliseconds: 301));
        // Flush all microtasks to let the update complete
        for (int i = 0; i < 5; i++) {
          async.flushMicrotasks();
        }

        expect(controller.loadingState, EmbedLoadingState.loaded);
        expect(controller.height, 300.0);

        // Wait for second update (500ms delay + update)
        async.elapse(const Duration(milliseconds: 501));

        // Ensure ALL microtasks for the second update finish
        for (int i = 0; i < 10; i++) {
          async.flushMicrotasks();
        }

        expect(controller.height, 350.0);

        // Confirm height was requested at least twice
        verify(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .called(greaterThanOrEqualTo(2));
      });
    });

    test('Twitter post-load event triggers height check', () async {
      fakeAsync((async) {
        final xParam = SocialEmbedParam(
          url: 'https://twitter.com/user/status/1',
          tracking: const EmbedTracking(
            source: 'test',
            contentId: '1',
            pageIdentifier: 'p',
            elementId: 'e',
          ),
        );
        final controller = EmbedController(param: xParam);
        final driver = EmbedWebViewDriver(
          controller: controller,
          webViewController: mockWebViewController,
        );

        driver.initEmbedWebview(
          backgroundColor: Colors.white,
          embedData: null,
          embedUrl: 'url',
          maxWidth: 400,
        );

        // Trigger OnTwitterLoaded
        final capturedOnTwitterLoaded =
            verify(() => mockWebViewController.addJavaScriptChannel(
                  'OnTwitterLoaded',
                  onMessageReceived: captureAny(named: 'onMessageReceived'),
                )).captured.last as void Function(JavaScriptMessage);

        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenAnswer((_) async => '400');

        capturedOnTwitterLoaded(const JavaScriptMessage(message: 'loaded'));

        async.elapse(const Duration(milliseconds: 301));
        expect(controller.height, 400.0);
        expect(controller.loadingState, EmbedLoadingState.loaded);
      });
    });

    test('NavigationDelegate triggers Twitter bind script', () async {
      final xParam = SocialEmbedParam(
        url: 'https://twitter.com/user/status/1',
        tracking: const EmbedTracking(
          source: 'test',
          contentId: '1',
          pageIdentifier: 'p',
          elementId: 'e',
        ),
      );
      final controller = EmbedController(param: xParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      // Trigger init for delegate building
      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'url',
        maxWidth: 400,
      );

      // Capture onPageFinished
      final capturedOnPageFinished =
          verify(() => mockPlatformNavigationDelegate.setOnPageFinished(
                captureAny(),
              )).captured.last as void Function(String);

      // Trigger it
      capturedOnPageFinished('https://twitter.com');

      // Verify bind script was run
      verify(() => mockWebViewController
          .runJavaScript(any(that: contains('twttr.events.bind')))).called(1);
    });

    test('NavigationDelegate triggers TikTok Photo mute', () async {
      final photoParam = SocialEmbedParam(
        url: 'https://www.tiktok.com/@u/photo/1',
        tracking: const EmbedTracking(
          source: 's',
          contentId: '1',
          pageIdentifier: 'p',
          elementId: 'e',
        ),
        embedType: EmbedType.tiktok,
      );
      final controller = EmbedController(param: photoParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'url',
        maxWidth: 400,
      );

      final capturedOnPageFinished =
          verify(() => mockPlatformNavigationDelegate.setOnPageFinished(
                captureAny(),
              )).captured.last as void Function(String);

      capturedOnPageFinished('https://tiktok.com');

      // Verify mute script (it uses document.querySelectorAll('video, audio'))
      verify(() => mockWebViewController.runJavaScript(
              any(that: contains("document.querySelectorAll('video, audio')"))))
          .called(1);
    });
  });
}
