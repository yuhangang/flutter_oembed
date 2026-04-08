import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';

class MockWebViewController extends Mock implements WebViewController {}

class MockWebResourceError extends Mock implements WebResourceError {}

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
    late MockWebViewController mockWebViewController;

    setUp(() {
      controller = EmbedController(
        param: SocialEmbedParam(
          url: 'https://twitter.com/user/status/123',
          embedType: EmbedType.x,
        ),
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
    });

    group('initEmbedWebview()', () {
      test('should return early if the embed is already successfully loaded',
          () async {
        controller.setLoadingState(EmbedLoadingState.loaded);
        controller.setHeight(100);

        final driver = EmbedWebViewDriver(
            controller: controller, webViewController: mockWebViewController);
        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: null,
            embedUrl: null,
            maxWidth: 640);

        verifyNever(() => mockWebViewController.setNavigationDelegate(any()));
      });

      test(
          'should force a reload if forceReload is true even if already loaded',
          () async {
        controller.setLoadingState(EmbedLoadingState.loaded);
        controller.setHeight(100);

        final driver = EmbedWebViewDriver(
            controller: controller, webViewController: mockWebViewController);
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
            controller: controller, webViewController: mockWebViewController);
        final data = const EmbedData(html: '', url: 'https://example.com');

        await driver.initEmbedWebview(
            backgroundColor: Colors.white,
            embedData: data,
            embedUrl: null,
            maxWidth: 640);

        verify(() => mockWebViewController.loadRequest(any())).called(1);
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
            controller: controller, webViewController: mockWebViewController);
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
            controller: controller, webViewController: mockWebViewController);
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
            controller: controller, webViewController: mockWebViewController);
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
                when(() =>
                        mockWebViewController.runJavaScriptReturningResult(any()))
                    .thenAnswer((_) async => '0');

                final driver = EmbedWebViewDriver(
                    controller: controller,
                    webViewController: mockWebViewController);
                driver.initEmbedWebview(
                    backgroundColor: Colors.white,
                    embedData: const EmbedData(html: '<div></div>'),
                    embedUrl: null,
                    maxWidth: 640);

                // Wait for init async work
                async.flushMicrotasks();

                capturedDelegate!.onPageFinished!('https://example.com');

                // Wait for all the delays in _handleEmbedPageFinished (approx 1500ms)
                async.elapse(const Duration(milliseconds: 2500));

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
                when(() =>
                        mockWebViewController.runJavaScriptReturningResult(any()))
                    .thenAnswer((_) async => '300');

                final driver = EmbedWebViewDriver(
                    controller: controller,
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
      test('should handle and swallow JavaScript execution errors', () async {
        when(() => mockWebViewController.runJavaScriptReturningResult(any()))
            .thenThrow(Exception('JS Error'));

        final driver = EmbedWebViewDriver(
            controller: controller, webViewController: mockWebViewController);
        await driver.updateEmbedPostHeight();

        // Should not crash
      });
    });
  });
}
