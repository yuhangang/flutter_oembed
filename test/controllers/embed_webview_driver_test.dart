import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';

class MockWebViewController extends Mock implements WebViewController {}

class MockWebResourceError extends Mock implements WebResourceError {}

class MockNavigationRequest extends Mock implements NavigationRequest {}

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
  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
    registerFallbackValue(Uri.parse('about:blank'));
    registerFallbackValue(NavigationDelegate());
    registerFallbackValue(LoadRequestParams(uri: Uri.parse('about:blank')));
    registerFallbackValue(const Color(0xFF000000));
    registerFallbackValue(JavaScriptMode.unrestricted);
  });

  group('EmbedWebViewDriver', () {
    late EmbedController controller;
    late SocialEmbedParam param;
    late MockWebViewController mockWebViewController;

    setUp(() {
      resetEmbedFocusCoordinatorForTests();
      param = SocialEmbedParam(
        url: 'https://twitter.com/user/status/123',
        embedType: EmbedType.x,
      );
      controller = buildController(
        param: param,
        config: const EmbedConfig(),
      );
      mockWebViewController = MockWebViewController();

      when(() => mockWebViewController.setBackgroundColor(any()))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.enableZoom(any()))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.setJavaScriptMode(any()))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.setUserAgent(any()))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.addJavaScriptChannel(any(),
              onMessageReceived: any(named: 'onMessageReceived')))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.setNavigationDelegate(any()))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.loadRequest(any(),
          headers: any(named: 'headers'))).thenAnswer((_) async {});
      when(() => mockWebViewController.loadHtmlString(any(),
          baseUrl: any(named: 'baseUrl'))).thenAnswer((_) async {});
      when(() => mockWebViewController.reload()).thenAnswer((_) async {});
      when(() => mockWebViewController.runJavaScript(any()))
          .thenAnswer((_) async {});
      when(() => mockWebViewController.runJavaScriptReturningResult(any()))
          .thenAnswer((_) async => '100');
      when(() => mockWebViewController.currentUrl())
          .thenAnswer((_) async => 'https://example.com');
    });

    group('focus arbitration', () {
      test('pauses non-focused embed when another visible embed has priority',
          () async {
        final secondController = buildController(
          param: SocialEmbedParam(
            url: 'https://youtube.com/watch?v=456',
            embedType: EmbedType.youtube,
          ),
          config: const EmbedConfig(),
        );
        secondController.setLoadingState(EmbedLoadingState.loaded);

        final secondWebViewController = MockWebViewController();
        when(() => secondWebViewController.runJavaScript(any()))
            .thenAnswer((_) async {});

        controller.setLoadingState(EmbedLoadingState.loaded);

        final firstDriver = EmbedWebViewDriver(
          controller: controller,
          param: param,
          webViewController: mockWebViewController,
        );
        final secondDriver = EmbedWebViewDriver(
          controller: secondController,
          param: SocialEmbedParam(
            url: 'https://youtube.com/watch?v=456',
            embedType: EmbedType.youtube,
          ),
          webViewController: secondWebViewController,
        );

        firstDriver.updateVisibilityFraction(0.9);
        secondDriver.updateVisibilityFraction(0.2);
        await Future<void>.delayed(Duration.zero);

        verify(() => secondWebViewController.runJavaScript(any()))
            .called(greaterThanOrEqualTo(1));
        verifyNever(() => mockWebViewController.runJavaScript(any()));

        secondController.dispose();
        firstDriver.dispose();
        secondDriver.dispose();
      });

      test('transfers focus when another embed becomes more visible', () async {
        final secondController = buildController(
          param: SocialEmbedParam(
            url: 'https://youtube.com/watch?v=456',
            embedType: EmbedType.youtube,
          ),
          config: const EmbedConfig(),
        );
        secondController.setLoadingState(EmbedLoadingState.loaded);

        final secondWebViewController = MockWebViewController();
        when(() => secondWebViewController.runJavaScript(any()))
            .thenAnswer((_) async {});

        controller.setLoadingState(EmbedLoadingState.loaded);

        final firstDriver = EmbedWebViewDriver(
          controller: controller,
          param: param,
          webViewController: mockWebViewController,
        );
        final secondDriver = EmbedWebViewDriver(
          controller: secondController,
          param: SocialEmbedParam(
            url: 'https://youtube.com/watch?v=456',
            embedType: EmbedType.youtube,
          ),
          webViewController: secondWebViewController,
        );

        firstDriver.updateVisibilityFraction(0.8);
        secondDriver.updateVisibilityFraction(0.3);
        secondDriver.updateVisibilityFraction(0.95);
        await Future<void>.delayed(Duration.zero);

        verify(() => mockWebViewController.runJavaScript(any()))
            .called(greaterThanOrEqualTo(1));
        verify(() => secondWebViewController.runJavaScript(any()))
            .called(greaterThanOrEqualTo(1));

        secondController.dispose();
        firstDriver.dispose();
        secondDriver.dispose();
      });
    });

    group('visibility', () {
      test('syncs navigation visibility from visible fraction updates', () {
        final driver = EmbedWebViewDriver(
          controller: controller,
          param: param,
          webViewController: mockWebViewController,
        );

        expect(embedDriverNavigationIsVisible(driver), isTrue);

        driver.updateVisibilityFraction(0);
        expect(embedDriverNavigationIsVisible(driver), isFalse);

        driver.updateVisibilityFraction(0.5);
        expect(embedDriverNavigationIsVisible(driver), isTrue);
      });
    });

    group('initEmbedWebview()', () {
      test('should return early if the embed is already successfully loaded',
          () async {
        controller.setLoadingState(EmbedLoadingState.loaded);
        controller.setHeight(100);

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: null,
            embedUrl: null,
            maxWidth: 640);

        verifyNever(() => mockWebViewController.setNavigationDelegate(any()));
      });

      test(
          'should preserve loaded state for provider variants that do not report height',
          () async {
        final tiktokV1Param = SocialEmbedParam(
          url: 'https://www.tiktok.com/@user/video/123',
          embedType: EmbedType.tiktok_v1,
        );
        final tiktokController = buildController(
          param: tiktokV1Param,
          config: const EmbedConfig(),
        );
        tiktokController.setLoadingState(EmbedLoadingState.loaded);
        try {
          final driver = EmbedWebViewDriver(
            controller: tiktokController,
            param: tiktokV1Param,
            webViewController: mockWebViewController,
          );

          await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: null,
            embedUrl: null,
            maxWidth: 640,
          );

          verifyNever(() => mockWebViewController.setNavigationDelegate(any()));
        } finally {
          tiktokController.dispose();
        }
      });

      test(
          'should force a reload if forceReload is true even if already loaded',
          () async {
        controller.setLoadingState(EmbedLoadingState.loaded);
        controller.setHeight(100);

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: const EmbedData(html: 'test'),
            embedUrl: null,
            maxWidth: 640,
            forceReload: true);

        verify(() => mockWebViewController.loadHtmlString(any(),
            baseUrl: any(named: 'baseUrl'))).called(1);
      });

      test(
          'should load the request URL when HTML is empty but a URL is present',
          () async {
        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        final data = const EmbedData(html: '', url: 'https://example.com');

        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: data,
            embedUrl: null,
            maxWidth: 640);

        verify(() => mockWebViewController.loadRequest(any())).called(1);
      });

      test('registers navigation intent tracking channel', () async {
        final driver = EmbedWebViewDriver(
          controller: controller,
          param: param,
          webViewController: mockWebViewController,
        );

        await driver.initEmbedWebview(
          backgroundColor: Colors.white,
          embedData:
              const EmbedData(html: '<a href="https://example.com">x</a>'),
          embedUrl: null,
          maxWidth: 640,
        );

        verify(() => mockWebViewController.addJavaScriptChannel(
              'NavigationIntentChannel',
              onMessageReceived: any(named: 'onMessageReceived'),
            )).called(1);
      });
    });

    group('onWebResourceError()', () {
      test('should set the state to noConnection for internet-related errors',
          () async {
        NavigationDelegate? capturedDelegate;
        when(() => mockWebViewController.setNavigationDelegate(any()))
            .thenAnswer((inv) {
          capturedDelegate = inv.positionalArguments.first;
          return Future.value();
        });

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: const EmbedData(html: '<div></div>'),
            embedUrl: null,
            maxWidth: 640);

        final error = MockWebResourceError();
        when(() => error.isForMainFrame).thenReturn(true);
        when(() => error.errorCode).thenReturn(-1009); // No internet
        when(() => error.description).thenReturn('No internet');

        capturedDelegate!.onWebResourceError!(error);
        expect(controller.loadingState, EmbedLoadingState.noConnection);
        expect(controller.lastError, isA<EmbedNetworkException>());
      });

      test('should set the state to noConnection for host lookup errors',
          () async {
        NavigationDelegate? capturedDelegate;
        when(() => mockWebViewController.setNavigationDelegate(any()))
            .thenAnswer((inv) {
          capturedDelegate = inv.positionalArguments.first;
          return Future.value();
        });

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: const EmbedData(html: '<div></div>'),
            embedUrl: null,
            maxWidth: 640);

        final error = MockWebResourceError();
        when(() => error.isForMainFrame).thenReturn(true);
        when(() => error.errorCode).thenReturn(-2); // Host lookup
        when(() => error.description).thenReturn('Host Lookup Error');

        capturedDelegate!.onWebResourceError!(error);
        expect(controller.loadingState, EmbedLoadingState.noConnection);
        expect(controller.lastError, isA<EmbedNetworkException>());
      });

      test('should ignore resource errors that are not for the main frame',
          () async {
        NavigationDelegate? capturedDelegate;
        when(() => mockWebViewController.setNavigationDelegate(any()))
            .thenAnswer((inv) {
          capturedDelegate = inv.positionalArguments.first;
          return Future.value();
        });

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: const EmbedData(html: '<div></div>'),
            embedUrl: null,
            maxWidth: 640);

        final error = MockWebResourceError();
        when(() => error.errorCode).thenReturn(0);
        when(() => error.description).thenReturn('Error');
        when(() => error.isForMainFrame).thenReturn(false);

        capturedDelegate!.onWebResourceError!(error);
        // State should remain loading
        expect(controller.loadingState, EmbedLoadingState.loading);
      });
    });

    group('onPageFinished()', () {
      test(
          'should set the controller state to error if the captured height is 0',
          () => fakeAsync((async) {
                NavigationDelegate? capturedDelegate;
                when(() => mockWebViewController.setNavigationDelegate(any()))
                    .thenAnswer((inv) {
                  capturedDelegate = inv.positionalArguments.first;
                  return Future.value();
                });
                when(() => mockWebViewController.currentUrl())
                    .thenAnswer((_) async => 'https://example.com');
                // Return 0 for height
                when(() => mockWebViewController.runJavaScriptReturningResult(
                    any())).thenAnswer((_) async => '0');

                final driver = EmbedWebViewDriver(
                    controller: controller,
                    param: param,
                    webViewController: mockWebViewController);
                driver.initEmbedWebview(
                    backgroundColor: Colors.white,
                    embedData: const EmbedData(html: '<div></div>'),
                    embedUrl: null,
                    maxWidth: 640);

                // Wait for init async work
                async.flushMicrotasks();

                capturedDelegate!.onPageFinished!('https://example.com');

                async.elapse(const Duration(milliseconds: 3500));
                async.flushMicrotasks();

                expect(controller.loadingState, EmbedLoadingState.error);
              }));

      test(
          'should set the controller height and state to loaded for a valid height',
          () => fakeAsync((async) {
                NavigationDelegate? capturedDelegate;
                when(() => mockWebViewController.setNavigationDelegate(any()))
                    .thenAnswer((inv) {
                  capturedDelegate = inv.positionalArguments.first;
                  return Future.value();
                });
                when(() => mockWebViewController.currentUrl())
                    .thenAnswer((_) async => 'https://example.com');
                when(() => mockWebViewController.runJavaScriptReturningResult(
                    any())).thenAnswer((_) async => '300');

                final driver = EmbedWebViewDriver(
                    controller: controller,
                    param: param,
                    webViewController: mockWebViewController);
                driver.initEmbedWebview(
                    backgroundColor: Colors.white,
                    embedData: const EmbedData(html: '<div></div>'),
                    embedUrl: null,
                    maxWidth: 640);

                async.flushMicrotasks();

                capturedDelegate!.onPageFinished!('https://example.com');

                async.elapse(const Duration(milliseconds: 2500));

                expect(controller.height, equals(300.0));
                expect(controller.loadingState, EmbedLoadingState.loaded);
              }));
    });

    group('updateEmbedPostHeight()', () {
      test('uses the robust DOM height query', () async {
        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenAnswer((_) async => '500');

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.updateEmbedPostHeight();

        expect(controller.height, 500.0);
        verify(() => mockWebViewController.runJavaScriptReturningResult(
              'Math.ceil(Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight));',
            )).called(1);
      });

      test('should handle and swallow JavaScript execution errors', () async {
        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenThrow(Exception('JS Error'));

        final driver = EmbedWebViewDriver(
            controller: controller,
            param: param,
            webViewController: mockWebViewController);
        await driver.updateEmbedPostHeight();

        // Should not crash
      });
    });

    test('refresh reloads and re-enters loading state', () async {
      final driver = EmbedWebViewDriver(
        controller: controller,
        param: param,
        webViewController: mockWebViewController,
      );
      controller.setLoadingState(EmbedLoadingState.loaded);

      await driver.refresh();

      expect(controller.loadingState, EmbedLoadingState.loading);
      verify(() => mockWebViewController.reload()).called(1);
    });

    test('refresh keeps trusted reload navigation inside the WebView',
        () async {
      NavigationDelegate? capturedDelegate;
      when(() => mockWebViewController.setNavigationDelegate(any()))
          .thenAnswer((invocation) {
        capturedDelegate = invocation.positionalArguments.first;
        return Future.value();
      });

      final driver = EmbedWebViewDriver(
        controller: controller,
        param: param,
        webViewController: mockWebViewController,
      );

      await driver.initEmbedWebview(
        backgroundColor: Colors.white,
        embedData: null,
        embedUrl: 'https://platform.twitter.com/embed',
        maxWidth: 400,
      );
      controller.setLoadingState(EmbedLoadingState.loaded);

      await driver.refresh();

      final request = MockNavigationRequest();
      when(() => request.url).thenReturn('https://platform.twitter.com/embed');
      when(() => request.isMainFrame).thenReturn(true);

      final decision = await capturedDelegate!.onNavigationRequest!(request);
      expect(decision, NavigationDecision.navigate);
    });

    test('dispose ignores cleanup failures', () async {
      when(() => mockWebViewController.loadRequest(any(),
          headers: any(named: 'headers'))).thenThrow(Exception('disposed'));
      when(() => mockWebViewController.setNavigationDelegate(any()))
          .thenThrow(Exception('delegate failed'));

      final driver = EmbedWebViewDriver(
        controller: controller,
        param: param,
        webViewController: mockWebViewController,
      );

      driver.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(controller.loadingState, EmbedLoadingState.loading);
    });
  });
}
