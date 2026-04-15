import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/models/youtube_embed_params.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

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
    when(() => mockPlatformNavigationDelegate.setOnHttpError(any()))
        .thenAnswer((_) async {});

    registerFallbackValue(const Color(0xFFFFFFFF));
    registerFallbackValue(JavaScriptMode.unrestricted);
    registerFallbackValue(Uri.parse('about:blank'));
    registerFallbackValue(LoadRequestMethod.get);
    registerFallbackValue(FakeNavigationDelegate());
    registerFallbackValue(JavaScriptChannelParams(
      name: 'test',
      onMessageReceived: (_) {},
    ));
    registerFallbackValue(const JavaScriptMessage(message: ''));
  });

  setUp(() {
    mockWebViewController = MockWebViewController();
    testParam = SocialEmbedParam(
      url: 'https://twitter.com/user/status/12345',
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
    when(() => mockWebViewController.currentUrl())
        .thenAnswer((_) async => 'https://example.com');
  });

  group('EmbedController', () {
    test('initial state is loading', () {
      final controller = buildController(param: testParam);
      expect(controller.loadingState, EmbedLoadingState.loading);
      expect(controller.height, isNull);
      expect(controller.isVisible, isTrue);
    });

    test('setHeight updates height and notifies listeners', () {
      final controller = buildController(param: testParam);
      bool listenerCalled = false;
      controller.addListener(() => listenerCalled = true);

      controller.setHeight(100.0);
      expect(controller.height, 100.0);
      expect(listenerCalled, isTrue);
    });

    test('setHeight ignores tiny downward height deltas', () {
      final controller = buildController(param: testParam);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setHeight(101.0);
      controller.setHeight(100.0);

      expect(controller.height, 101.0);
      expect(notifications, 1);
    });

    test('setHeight honors configured downward delta threshold', () {
      final controller = buildController(
        param: testParam,
        config: const EmbedConfig(heightUpdateDeltaThreshold: 5),
      );
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setHeight(100.0);
      controller.setHeight(96.0);
      expect(controller.height, 100.0);

      controller.setHeight(95.0);
      expect(controller.height, 95.0);
      expect(notifications, 2);
    });

    test('setHeight accepts tiny upward adjustments to avoid clipping', () {
      final controller = buildController(param: testParam);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setHeight(100.0);
      controller.setHeight(101.0);

      expect(controller.height, 101.0);
      expect(notifications, 2);
    });

    test('setLoadingState updates state and notifies listeners', () {
      final controller = buildController(param: testParam);
      bool listenerCalled = false;
      controller.addListener(() => listenerCalled = true);

      controller.setLoadingState(EmbedLoadingState.loaded);
      expect(controller.loadingState, EmbedLoadingState.loaded);
      expect(listenerCalled, isTrue);
    });

    test('setLoadingState stores and clears lastError correctly', () {
      final controller = buildController(param: testParam);
      final error = StateError('broken');

      controller.setLoadingState(EmbedLoadingState.error, error: error);
      expect(controller.lastError, same(error));

      controller.setLoadingState(EmbedLoadingState.loading);
      expect(controller.lastError, isNull);
    });

    test('updateVisibility updates visibility and calls callback', () {
      final controller = buildController(param: testParam);
      bool callbackCalledWith = true;

      controller.updateVisibility(false, onVisibilityChange: (visible) {
        callbackCalledWith = visible;
      });

      expect(controller.isVisible, isFalse);
      expect(callbackCalledWith, isFalse);
    });

    test('disposed controller ignores state mutations', () {
      final controller = buildController(param: testParam);
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
        final controller = buildController(
          param: testParam,
          config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
        );

        controller.startLoadTimeout();
        expect(controller.loadingState, EmbedLoadingState.loading);

        async.elapse(const Duration(seconds: 6));
        expect(controller.loadingState, EmbedLoadingState.error);
        expect(controller.lastError, isA<EmbedTimeoutException>());
      });
    });

    test('no-op after dispose', () {
      final controller = buildController(
        param: SocialEmbedParam(url: 'test', embedType: EmbedType.other),
      );

      bool notified = false;
      controller.addListener(() => notified = true);

      controller.dispose();

      controller.setHeight(100);
      controller.setLoadingState(EmbedLoadingState.loaded);
      controller.setDidRetry();
      controller.updateVisibility(false, onVisibilityChange: (_) {});

      expect(notified, isFalse);
    });

    test('updateVisibility calls callback', () {
      final controller = buildController(
        param: SocialEmbedParam(url: 'test', embedType: EmbedType.other),
      );

      bool callbackCalled = false;
      controller.updateVisibility(false, onVisibilityChange: (visible) {
        callbackCalled = true;
        expect(visible, isFalse);
      });

      expect(callbackCalled, isTrue);
      expect(controller.isVisible, isFalse);
    });

    test('synchronize resets runtime state when params change', () {
      final initialParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=old',
        embedType: EmbedType.youtube,
      );
      final nextParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=old',
        embedType: EmbedType.youtube,
        embedParams: const YoutubeEmbedParams(autoplay: true),
      );
      final controller = buildController(
        param: initialParam,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      );

      controller.setHeight(240);
      controller.setDidRetry();
      controller.setLoadingState(
        EmbedLoadingState.error,
        error: StateError('stale'),
      );

      controller.synchronize(
        contentKey: nextParam,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 8)),
      );

      expect(controller.config?.loadTimeout, const Duration(seconds: 8));
      expect(controller.loadingState, EmbedLoadingState.loading);
      expect(controller.height, isNull);
      expect(controller.didRetry, isFalse);
      expect(controller.lastError, isNull);
    });

    test('synchronize disposes the bound driver and bumps embed revision', () {
      final initialParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=old',
        embedType: EmbedType.youtube,
      );
      final nextParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=new',
        embedType: EmbedType.youtube,
      );
      final controller = EmbedController();

      var disposeCalls = 0;
      final driver = Object();
      controller.bindDriver(
        driver,
        contentKey: initialParam,
        onDispose: () => disposeCalls++,
      );

      controller.synchronize(contentKey: nextParam);

      expect(disposeCalls, 1);
      expect(controller.boundDriver, isNull);
      expect(controller.embedRevision, 1);
    });

    test(
        'synchronize preserves the bound driver and revision for config-only updates',
        () {
      final param = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=stable',
        embedType: EmbedType.youtube,
      );
      final controller = buildController(
        param: param,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      );
      final initialRevision = controller.embedRevision;

      var disposeCalls = 0;
      final driver = Object();
      controller.bindDriver(
        driver,
        contentKey: param,
        onDispose: () => disposeCalls++,
      );

      controller.synchronize(
        contentKey: param,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 8)),
      );

      expect(disposeCalls, 0);
      expect(controller.boundDriver, same(driver));
      expect(controller.boundDriverContentKey, same(param));
      expect(controller.embedRevision, initialRevision);
      expect(controller.config?.loadTimeout, const Duration(seconds: 8));
    });

    test('setEmbedData stores data and clears error retry state', () {
      final controller = buildController(param: testParam);
      const data = EmbedData(
        html: '<div>cached</div>',
        providerUrl: 'https://www.youtube.com',
      );

      controller.setLoadingState(
        EmbedLoadingState.error,
        error: StateError('broken'),
      );
      controller.setDidRetry();
      controller.setEmbedData(data);

      expect(controller.embedData, data);
      expect(controller.loadingState, EmbedLoadingState.loading);
      expect(controller.didRetry, isFalse);
      expect(controller.lastError, isNull);
    });

    test('synchronize clears embedData when content changes', () {
      final initialParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=old',
        embedType: EmbedType.youtube,
      );
      final nextParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=new',
        embedType: EmbedType.youtube,
      );
      final controller = buildController(param: initialParam);

      controller.setEmbedData(
        const EmbedData(
          html: '<div>cached</div>',
          providerUrl: 'https://www.youtube.com',
        ),
      );

      controller.synchronize(contentKey: nextParam);

      expect(controller.embedData, isNull);
    });

    test('setHeight ignores non-finite values', () {
      final controller = buildController(param: testParam);
      controller.setHeight(double.infinity);
      expect(controller.height, isNull);
      controller.setHeight(double.nan);
      expect(controller.height, isNull);
    });

    test('setHeight ignores zero and negative values', () {
      final controller = buildController(param: testParam);
      controller.setHeight(0);
      expect(controller.height, isNull);
      controller.setHeight(-10);
      expect(controller.height, isNull);
    });

    test('setDidRetry only notifies once', () {
      final controller = buildController(param: testParam);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setDidRetry();
      controller.setDidRetry();

      expect(controller.didRetry, isTrue);
      expect(notifications, 1);
    });

    test('cancelLoadTimeout prevents timeout from firing', () {
      fakeAsync((async) {
        final controller = buildController(
          param: testParam,
          config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
        );

        controller.startLoadTimeout();
        async.elapse(const Duration(seconds: 3));
        controller.cancelLoadTimeout();
        async.elapse(const Duration(seconds: 5));

        expect(controller.loadingState, EmbedLoadingState.loading);
      });
    });

    test('timeout does not fire when already loaded', () {
      fakeAsync((async) {
        final controller = buildController(
          param: testParam,
          config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
        );

        controller.startLoadTimeout();
        controller.setLoadingState(EmbedLoadingState.loaded);

        async.elapse(const Duration(seconds: 10));
        expect(controller.loadingState, EmbedLoadingState.loaded);
      });
    });

    test('uses default 20-second timeout when no config provided', () {
      fakeAsync((async) {
        final controller = buildController(param: testParam);
        controller.startLoadTimeout();

        async.elapse(const Duration(seconds: 19));
        expect(controller.loadingState, EmbedLoadingState.loading);

        async.elapse(const Duration(seconds: 1));
        expect(controller.loadingState, EmbedLoadingState.error);
      });
    });

    test('setLoadingState preserves existing error on noConnection', () {
      final controller = buildController(param: testParam);
      final error = StateError('original');

      controller.setLoadingState(EmbedLoadingState.error, error: error);
      controller.setLoadingState(EmbedLoadingState.noConnection);

      expect(controller.lastError, same(error));
    });

    test('double dispose does not throw', () {
      final controller = buildController(param: testParam);
      controller.dispose();
      expect(() => controller.dispose(), returnsNormally);
    });

    test('setLoadingState does not notify when state and error are unchanged',
        () {
      final controller = buildController(param: testParam);
      controller.setLoadingState(EmbedLoadingState.loaded);

      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setLoadingState(EmbedLoadingState.loaded);
      expect(notifications, 0);
    });

    test('updateVisibility does not notify when value unchanged', () {
      final controller = buildController(param: testParam);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.updateVisibility(true, onVisibilityChange: (_) {});
      expect(notifications, 0); // already true
    });
  });

  group('EmbedWebViewDriver', () {
    test('initEmbedWebview configures webViewController correctly', () async {
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
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
        embedType: EmbedType.youtube,
      );
      final controller = buildController(param: youtubeParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: youtubeParam,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl:
            'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1',
        maxWidth: 400,
      );

      verify(() => mockWebViewController.loadRequest(
            Uri.parse(
              'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1',
            ),
            headers: const <String, String>{
              'Referer': 'https://www.youtube-nocookie.com',
            },
            method: LoadRequestMethod.get,
            body: null,
          )).called(1);
    });

    test('dispose cleans up timers and webViewController', () async {
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
        webViewController: mockWebViewController,
      );

      driver.dispose();
      await Future<void>.delayed(Duration.zero);

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
      );
      final controller = buildController(param: tiktokParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: tiktokParam,
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
      );
      final controller = buildController(param: xParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: xParam,
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
      );
      final controller = buildController(param: fbParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: fbParam,
        webViewController: mockWebViewController,
      );
      // ignore: prefer_const_constructors
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
        embedType: EmbedType.tiktok,
      );
      final controller = buildController(param: photoParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: photoParam,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://www.tiktok.com/embed/v3/123',
        maxWidth: 400,
      );
      controller.setLoadingState(EmbedLoadingState.loaded);

      await driver.pauseMedias();
      verify(() => mockWebViewController.runJavaScript(
            any(that: contains('"type":"pause"')),
          )).called(1);

      final videoParam = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=123',
      );
      final videoController = buildController(param: videoParam);
      final videoDriver = EmbedWebViewDriver(
        controller: videoController,
        param: videoParam,
        webViewController: mockWebViewController,
      );

      await videoDriver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://www.youtube.com/embed/123',
        maxWidth: 400,
      );
      videoController.setLoadingState(EmbedLoadingState.loaded);

      await videoDriver.pauseMedias();
      verify(() => mockWebViewController.runJavaScript(any()))
          .called(greaterThan(0));
    });

    test('public media control API delegates through bound driver', () async {
      final tiktokParam = SocialEmbedParam(
        url: 'https://www.tiktok.com/@user/video/123',
        embedType: EmbedType.tiktok_v1,
      );
      final controller = buildController(param: tiktokParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: tiktokParam,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://www.tiktok.com/player/v1/123',
        maxWidth: 400,
      );
      controller.setLoadingState(EmbedLoadingState.loaded);

      await controller.pauseMedia();
      await controller.resumeMedia();
      await controller.muteMedia();
      await controller.unmuteMedia();

      verify(() => mockWebViewController.runJavaScript(
            any(that: contains('"type":"pause"')),
          )).called(1);
      verify(() => mockWebViewController.runJavaScript(
            any(that: contains('"type":"play"')),
          )).called(1);
      verify(() => mockWebViewController.runJavaScript(
            any(that: contains('"type":"mute"')),
          )).called(1);
      verify(() => mockWebViewController.runJavaScript(
            any(that: contains('"type":"unMute"')),
          )).called(1);
    });

    test('updateEmbedPostHeight success handles new height', () async {
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
        webViewController: mockWebViewController,
      );
      when(() => mockWebViewController.runJavaScriptReturningResult(any()))
          .thenAnswer((_) async => '500');

      await driver.updateEmbedPostHeight();
      expect(controller.height, 500.0);
    });

    test('refresh reloads and resets state', () {
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
        webViewController: mockWebViewController,
      );

      driver.refresh();
      verify(() => mockWebViewController.reload()).called(1);
    });

    test('initEmbedWebview returns early if already loaded', () async {
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
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
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
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

    test('ignores generic cross-origin script errors after load', () async {
      final tiktokParam = SocialEmbedParam(
        url: 'https://www.tiktok.com/@user/video/123',
        embedType: EmbedType.tiktok_v1,
      );
      final controller = buildController(param: tiktokParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: tiktokParam,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData:
            const EmbedData(html: 'https://www.tiktok.com/player/v1/123'),
        embedUrl: null,
        maxWidth: 400,
      );

      controller.setLoadingState(EmbedLoadingState.loaded);

      final errorChannel =
          verify(() => mockWebViewController.addJavaScriptChannel(
                'ErrorChannel',
                onMessageReceived: captureAny(named: 'onMessageReceived'),
              )).captured.last as void Function(JavaScriptMessage);

      errorChannel(const JavaScriptMessage(
        message: 'JS_ERROR: Script error. at :0',
      ));

      expect(controller.loadingState, EmbedLoadingState.loaded);

      await controller.pauseMedia();
      verify(() => mockWebViewController.runJavaScript(
            any(that: contains('"type":"pause"')),
          )).called(1);
    });

    test('updateEmbedPostHeight handles errors gracefully', () async {
      final controller = buildController(param: testParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: testParam,
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
          embedType: EmbedType.youtube,
        );
        final controller = buildController(param: generalParam);
        final driver = EmbedWebViewDriver(
          controller: controller,
          param: generalParam,
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
        async.flushMicrotasks();

        // Wait for first update (300ms delay + update)
        async.elapse(const Duration(milliseconds: 305));
        async.flushMicrotasks();

        expect(controller.loadingState, EmbedLoadingState.loaded);
        expect(controller.height, 300.0);

        // Wait for second update (500ms delay + update)
        async.elapse(const Duration(milliseconds: 505));
        async.flushMicrotasks();

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
        );
        final controller = buildController(param: xParam);
        final driver = EmbedWebViewDriver(
          controller: controller,
          param: xParam,
          webViewController: mockWebViewController,
        );

        driver.initEmbedWebview(
          backgroundColor: Colors.white,
          embedData: null,
          embedUrl: 'url',
          maxWidth: 400,
        );
        async.flushMicrotasks();

        // Trigger OnTwitterLoaded
        final capturedOnTwitterLoaded =
            verify(() => mockWebViewController.addJavaScriptChannel(
                  'OnTwitterLoaded',
                  onMessageReceived: captureAny(named: 'onMessageReceived'),
                )).captured.last as void Function(JavaScriptMessage);
        final capturedOnPageFinished =
            verify(() => mockPlatformNavigationDelegate.setOnPageFinished(
                  captureAny(),
                )).captured.last as void Function(String);

        when(() => mockWebViewController.currentUrl())
            .thenAnswer((_) async => 'https://twitter.com');
        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenAnswer((_) async => '400');

        capturedOnPageFinished('https://twitter.com');
        async.flushMicrotasks();

        capturedOnTwitterLoaded(const JavaScriptMessage(message: 'loaded'));
        async.flushMicrotasks();

        // Wait for first rendering delay (300ms)
        async.elapse(const Duration(milliseconds: 305));
        async.flushMicrotasks();

        expect(controller.height, 400.0);
        expect(controller.loadingState, EmbedLoadingState.loaded);
      });
    });

    test('Twitter falls back to default page-finished handling after 2 seconds',
        () async {
      fakeAsync((async) {
        final xParam = SocialEmbedParam(
          url: 'https://twitter.com/user/status/1',
        );
        final controller = buildController(param: xParam);
        final driver = EmbedWebViewDriver(
          controller: controller,
          param: xParam,
          webViewController: mockWebViewController,
        );

        driver.initEmbedWebview(
          backgroundColor: Colors.white,
          embedData: null,
          embedUrl: 'url',
          maxWidth: 400,
        );
        async.flushMicrotasks();

        final capturedOnPageFinished =
            verify(() => mockPlatformNavigationDelegate.setOnPageFinished(
                  captureAny(),
                )).captured.last as void Function(String);

        when(() => mockWebViewController.currentUrl())
            .thenAnswer((_) async => 'https://twitter.com');
        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenAnswer((_) async => '400');

        capturedOnPageFinished('https://twitter.com');
        async.flushMicrotasks();

        expect(controller.loadingState, EmbedLoadingState.loading);

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 305));
        async.flushMicrotasks();

        expect(controller.height, 400.0);
        expect(controller.loadingState, EmbedLoadingState.loaded);
      });
    });

    test('NavigationDelegate triggers Twitter bind script', () async {
      final xParam = SocialEmbedParam(
        url: 'https://twitter.com/user/status/1',
      );
      final controller = buildController(param: xParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: xParam,
        webViewController: mockWebViewController,
      );

      //
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

      // Wait for any async handling in onPageFinished
      await Future.delayed(Duration.zero);

      // Verify bind script was run (from TwitterProviderStrategy)
      verify(() => mockWebViewController.runJavaScript(
          any(that: contains("twttr.events.bind('loaded'")))).called(1);
    });

    test('NavigationDelegate triggers TikTok Photo mute', () async {
      final photoParam = SocialEmbedParam(
        url: 'https://www.tiktok.com/@u/photo/1',
        embedType: EmbedType.tiktok,
      );
      final controller = buildController(param: photoParam);
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: photoParam,
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

      // Wait for any async handling (it's async in NavigationDelegate callback)
      await Future.delayed(Duration.zero);

      // Verify TikTok page-finish still applies top-level mute and pause.
      verify(() => mockWebViewController.runJavaScript(
              any(that: contains("document.querySelectorAll('video, audio')"))))
          .called(2);
    });
  });
}
