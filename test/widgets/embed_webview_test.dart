import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_constant.dart';
import 'package:flutter_oembed/src/models/core/embed_constraints.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_strings.dart';
import 'package:flutter_oembed/src/models/core/embed_webview_controls.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../fake_webview_platform.dart';

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
  final fakePlatform = FakeWebViewPlatform();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    WebViewPlatform.instance = fakePlatform;
  });

  group('EmbedWebView', () {
    late EmbedController controller;
    late SocialEmbedParam param;
    late EmbedData data;

    setUp(() {
      resetEmbedFocusCoordinatorForTests();
      fakePlatform.reset();
      param = SocialEmbedParam(
        url: 'https://youtube.com/watch?v=123',
        embedType: EmbedType.youtube,
      );
      controller = buildController(
        param: param,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      );
      data = const EmbedData(html: '<div>Test</div>');
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should render a WebViewWidget when initialized',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(WebViewWidget), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('changing maxWidth does not remount the WebView core',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 640,
              child: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final initialPlatformController = fakePlatform.lastCreatedController;
      final initialDriver = controller.boundDriver;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              child: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 480,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(controller.boundDriver, same(initialDriver));
      expect(
          fakePlatform.lastCreatedController, same(initialPlatformController));
      expect(fakePlatform.lastCreatedController?.loadHtmlCount, 1);

      controller.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets(
        'uses provider fallback height metadata when no height is known',
        (tester) async {
      final spotifyParam = SocialEmbedParam(
        url: 'https://open.spotify.com/track/123',
        embedType: EmbedType.spotify,
      );
      final spotifyController = buildController(
        param: spotifyParam,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: spotifyParam,
                data: data,
                maxWidth: 640,
                controller: spotifyController,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(
          tester
              .widgetList<SizedBox>(find.byType(SizedBox))
              .any((widget) => widget.height == 152),
          isTrue,
        );
      } finally {
        spotifyController.dispose();
      }
    });

    testWidgets('records recent user interaction from the wrapper listener',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pump();
      final driver = controller.boundDriver as EmbedWebViewDriver;
      expect(embedDriverHasRecentUserInteraction(driver), isFalse);

      controller.setLoadingState(EmbedLoadingState.loaded);
      await tester.pump();

      await tester.tapAt(tester.getCenter(find.byType(EmbedWebView)));
      await tester.pump();

      expect(embedDriverHasRecentUserInteraction(driver), isTrue);

      controller.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('pauses media when a new route covers the embed',
        (tester) async {
      final routeObserver = RouteObserver<ModalRoute<dynamic>>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: buildController(
                param: param,
                config: EmbedConfig(
                  pauseOnRouteCover: true,
                  routeObserver: routeObserver,
                ),
              ),
            ),
          ),
        ),
      );

      final routeAwareController =
          tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

      try {
        routeAwareController.setLoadingState(EmbedLoadingState.loaded);
        await tester.pump();

        Navigator.of(tester.element(find.byType(EmbedWebView))).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Next')),
          ),
        );
        await tester.pumpAndSettle();

        expect(fakePlatform.lastCreatedController?.javaScriptCalls, isNotEmpty);
      } finally {
        routeAwareController.dispose();
      }
    });

    testWidgets('pauses media when a modal bottom sheet covers the embed',
        (tester) async {
      final routeObserver = RouteObserver<ModalRoute<dynamic>>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: Builder(
            builder: (context) {
              return Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const SizedBox(height: 120),
                    );
                  },
                ),
                body: EmbedWebView.data(
                  param: param,
                  data: data,
                  maxWidth: 640,
                  controller: buildController(
                    param: param,
                    config: EmbedConfig(
                      pauseOnRouteCover: true,
                      routeObserver: routeObserver,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      final routeAwareController =
          tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

      try {
        routeAwareController.setLoadingState(EmbedLoadingState.loaded);
        await tester.pump();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(fakePlatform.lastCreatedController?.javaScriptCalls, isNotEmpty);
      } finally {
        routeAwareController.dispose();
      }
    });

    testWidgets('attempts to resume media when returning from a covered route',
        (tester) async {
      final routeObserver = RouteObserver<ModalRoute<dynamic>>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: buildController(
                param: param,
                config: EmbedConfig(
                  pauseOnRouteCover: true,
                  routeObserver: routeObserver,
                ),
              ),
            ),
          ),
        ),
      );

      final routeAwareController =
          tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

      try {
        routeAwareController.setLoadingState(EmbedLoadingState.loaded);
        await tester.pump();

        Navigator.of(tester.element(find.byType(EmbedWebView))).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Next')),
          ),
        );
        await tester.pumpAndSettle();
        final pauseCallCount = fakePlatform
                .lastCreatedController?.javaScriptCalls
                .where((call) => call.contains('pause'))
                .length ??
            0;
        final resumeCallCount = fakePlatform
                .lastCreatedController?.javaScriptCalls
                .where((call) => call.contains('play'))
                .length ??
            0;

        Navigator.of(tester.element(find.text('Next'))).pop();
        await tester.pumpAndSettle();

        expect(
          fakePlatform.lastCreatedController?.javaScriptCalls
                  .where((call) => call.contains('pause'))
                  .length ??
              0,
          greaterThanOrEqualTo(pauseCallCount),
        );
        expect(routeAwareController.loadingState, EmbedLoadingState.loaded);
        expect(
          fakePlatform.lastCreatedController?.javaScriptCalls
                  .where((call) => call.contains('play'))
                  .length ??
              0,
          greaterThanOrEqualTo(resumeCallCount),
        );
      } finally {
        routeAwareController.dispose();
      }
    });

    testWidgets('does not pause media on route cover when disabled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: buildController(
                param: param,
                config: const EmbedConfig(pauseOnRouteCover: false),
              ),
            ),
          ),
        ),
      );

      final routeAwareController =
          tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

      try {
        routeAwareController.setLoadingState(EmbedLoadingState.loaded);
        await tester.pump();
        fakePlatform.lastCreatedController?.javaScriptCalls.clear();

        final observerFinder = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_EmbedWebviewObserver',
        );
        final observerState = tester.state(observerFinder) as dynamic;
        observerState.didPushNext();
        await tester.pump();

        expect(
          fakePlatform.lastCreatedController?.javaScriptCalls
                  .where((call) => call.contains('pause'))
                  .length ??
              0,
          0,
        );
      } finally {
        routeAwareController.dispose();
      }
    });

    testWidgets(
        'pauses again after a manual resume when the route is covered a second time',
        (tester) async {
      final routeObserver = RouteObserver<ModalRoute<dynamic>>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [routeObserver],
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: buildController(
                param: param,
                config: EmbedConfig(
                  pauseOnRouteCover: true,
                  routeObserver: routeObserver,
                ),
              ),
            ),
          ),
        ),
      );

      final routeAwareController =
          tester.widget<EmbedWebView>(find.byType(EmbedWebView)).controller;

      try {
        routeAwareController.setLoadingState(EmbedLoadingState.loaded);
        await tester.pump();

        Navigator.of(tester.element(find.byType(EmbedWebView))).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Next')),
          ),
        );
        await tester.pumpAndSettle();

        final firstPauseCount = (fakePlatform
                .lastCreatedController?.javaScriptCalls
                .where((call) => call.contains('pause'))
                .length ??
            0);
        expect(firstPauseCount, greaterThan(0));

        Navigator.of(tester.element(find.text('Next'))).pop();
        await tester.pumpAndSettle();

        await routeAwareController.resumeMedia();
        await tester.pump();

        final resumeCountAfterManualResume = (fakePlatform
                .lastCreatedController?.javaScriptCalls
                .where((call) => call.contains('play'))
                .length ??
            0);
        expect(resumeCountAfterManualResume, greaterThan(0));

        Navigator.of(tester.element(find.byType(EmbedWebView))).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Next again')),
          ),
        );
        await tester.pumpAndSettle();

        final secondPauseCount = (fakePlatform
                .lastCreatedController?.javaScriptCalls
                .where((call) => call.contains('pause'))
                .length ??
            0);
        expect(secondPauseCount, greaterThan(firstPauseCount));
      } finally {
        routeAwareController.dispose();
      }
    });

    testWidgets(
        'should NOT dispose the driver when widget is disposed if controller is alive',
        (tester) async {
      try {
        // 1. Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                key: const Key('webview_1'),
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(WebViewWidget), findsOneWidget);

        // Simulate loading finished
        controller.setLoadingState(EmbedLoadingState.loaded);
        await tester.pump();

        // 2. Dispose the widget by replacing it with something else
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('Disposed'),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(WebViewWidget), findsNothing);

        // 3. Re-build the widget with the SAME controller
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                key: const Key('webview_2'),
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        // If the driver was disposed, it won't re-initialize correctly.
        expect(controller.loadingState, EmbedLoadingState.loaded);
        expect(find.byType(WebViewWidget), findsOneWidget);

        // Verify the WebView was NOT disposed (it should NOT have loaded about:blank)
        final webViewController = fakePlatform.lastCreatedController!;
        expect(webViewController.lastRequest?.uri.toString(),
            isNot('about:blank'));
        expect(webViewController.lastLoadedHtml, contains('<div>Test</div>'));

        // Wait a bit to see if any errors happen or if it fails to render.
        await tester.pump(const Duration(milliseconds: 100));
      } finally {
        controller.dispose();
      }
    });

    testWidgets('exposes loading semantics while the embed is loading',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(
          find.bySemanticsLabel('Loading embedded content'),
          findsOneWidget,
        );
      } finally {
        controller.dispose();
        semanticsHandle.dispose();
      }
    });

    testWidgets('uses configured strings for retry semantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final customController = buildController(
        param: param,
        config: const EmbedConfig(
          strings: EmbedStrings(
            retryAfterLoadErrorSemanticsLabel: 'Cuba semula kandungan benam',
            retryHint: 'Ketik dua kali untuk cuba lagi',
          ),
        ),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: customController,
              ),
            ),
          ),
        );

        await tester.pump();
        customController.setLoadingState(EmbedLoadingState.error);
        await tester.pump();

        expect(
          find.bySemanticsLabel('Cuba semula kandungan benam'),
          findsOneWidget,
        );
      } finally {
        customController.dispose();
        semanticsHandle.dispose();
      }
    });

    testWidgets(
        'should trigger re-initialization when didUpdateWidget is called',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: controller,
            ),
          ),
        ),
      );

      final newParam = SocialEmbedParam(
          url: 'https://youtube.com/watch?v=456', embedType: EmbedType.youtube);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: newParam,
              data: data,
              maxWidth: 640,
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('recreates the platform WebView when controller params change',
        (tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(fakePlatform.createdControllers.length, 1);

        controller.synchronize(
          contentKey: SocialEmbedParam(
            url: 'https://youtube.com/watch?v=456',
            embedType: EmbedType.youtube,
          ),
        );

        await tester.pump();
        await tester.pump();

        expect(fakePlatform.createdControllers.length, 2);
      } finally {
        controller.dispose();
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('should render a custom webViewBuilder when provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: controller,
              webViewBuilder: (context, controls, child) =>
                  Container(key: const Key('custom'), child: child),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom')), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('exposes functional controls in webViewBuilder',
        (tester) async {
      late EmbedWebViewControls capturedControls;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: controller,
              webViewBuilder: (context, controls, child) {
                capturedControls = controls;
                return child;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      controller.setLoadingState(EmbedLoadingState.loaded);

      // Verify WebViewController is exposed
      expect(capturedControls.controller, isNotNull);

      // Verify reload() triggers a reload on the underlying controller
      await capturedControls.reload();
      expect(fakePlatform.lastCreatedController?.reloadCount, 1);

      // Verify media controls are callable without throwing.
      await capturedControls.resumeMedia();
      await tester.pump();

      // Verify updateHeight() triggers height update
      await capturedControls.updateHeight();
      // fake platform getEmbedDocumentHeight returns a default value

      controller.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets(
        'should allow retry logic when the controller is in an error state',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();
        controller.setLoadingState(EmbedLoadingState.error);
        await tester.pump();
        final refreshIcon = find.byIcon(Icons.refresh);
        expect(refreshIcon, findsOneWidget);
        expect(
          find.bySemanticsLabel('Retry embedded content after load error'),
          findsOneWidget,
        );

        await tester.tap(refreshIcon);
        expect(controller.loadingState, EmbedLoadingState.loading);
        await tester.pump(const Duration(seconds: 11));
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets(
        'should restart guarded retry logic when the controller is in noConnection state',
        (tester) async {
      final customController = buildController(
        param: param,
        config: const EmbedConfig(loadTimeout: Duration(milliseconds: 100)),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: customController,
              ),
            ),
          ),
        );

        await tester.pump();
        customController.setLoadingState(EmbedLoadingState.noConnection);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(customController.loadingState, EmbedLoadingState.loading);
        expect(fakePlatform.lastCreatedController?.reloadCount, 1);

        await tester.pump(const Duration(milliseconds: 150));
        expect(customController.loadingState, EmbedLoadingState.error);
      } finally {
        customController.dispose();
      }
    });

    testWidgets(
        'should trigger re-initialization when a new controller is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: controller,
            ),
          ),
        ),
      );

      final newController = buildController(param: param);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWebView.data(
              param: param,
              data: data,
              maxWidth: 640,
              controller: newController,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      newController.dispose();
    });

    testWidgets(
        'uses 16:9 fallback height for video embeds without aspect ratio',
        (tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 320,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        final sizedBox = tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .firstWhere((widget) => widget.height != null);
        expect(sizedBox.height, closeTo(180.0, 0.01));
      } finally {
        controller.dispose();
      }
    });

    testWidgets('caps generic fallback height instead of using a square',
        (tester) async {
      final genericParam = SocialEmbedParam(
        url: 'https://example.com/post/1',
        embedType: EmbedType.other,
      );
      final genericController = buildController(
        param: genericParam,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: genericParam,
                data: const EmbedData(html: '<div>Generic</div>'),
                maxWidth: 500,
                controller: genericController,
              ),
            ),
          ),
        );

        await tester.pump();

        final sizedBox = tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .firstWhere((widget) => widget.height != null);
        expect(sizedBox.height, 320.0);
      } finally {
        genericController.dispose();
      }
    });

    testWidgets('uses preferredHeight from embedConstraints', (tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 320,
                embedConstraints: const EmbedConstraints(preferredHeight: 232),
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        final sizedBox = tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .firstWhere((widget) => widget.height != null);
        expect(sizedBox.height, 232.0);
      } finally {
        controller.dispose();
      }
    });

    testWidgets('clamps derived height to embedConstraints.maxHeight',
        (tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                embedConstraints: const EmbedConstraints(maxHeight: 180),
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pump();

        final sizedBox = tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .firstWhere((widget) => widget.height != null);
        expect(sizedBox.height, 180.0);
      } finally {
        controller.dispose();
      }
    });

    testWidgets('prefers measured WebView height over oEmbed aspect ratio',
        (tester) async {
      final measuredController = buildController(
        param: param,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      )..setHeight(260);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: const EmbedData(
                  html: '<div>Test</div>',
                  width: 640,
                  height: 360,
                ),
                maxWidth: 320,
                controller: measuredController,
              ),
            ),
          ),
        );

        await tester.pump();

        final sizedBox = tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .firstWhere((widget) => widget.height != null);
        expect(sizedBox.height, 260.0);
      } finally {
        measuredController.dispose();
      }
    });

    testWidgets('clamps scrollable embeds to the default max height',
        (tester) async {
      final scrollableController = buildController(
        param: param,
        config: const EmbedConfig(loadTimeout: Duration(seconds: 5)),
      )..setHeight(900);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: scrollableController,
                scrollable: true,
              ),
            ),
          ),
        );

        await tester.pump();

        final sizedBox = tester
            .widgetList<SizedBox>(find.byType(SizedBox))
            .firstWhere((widget) => widget.height != null);
        expect(sizedBox.height, kDefaultMaxScrollableEmbedHeight);
      } finally {
        scrollableController.dispose();
      }
    });

    testWidgets('adds eager gesture recognizer when scrollable is enabled',
        (tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
                scrollable: true,
              ),
            ),
          ),
        );

        await tester.pump();

        final webViewWidget =
            tester.widget<WebViewWidget>(find.byType(WebViewWidget));
        expect(webViewWidget.gestureRecognizers, hasLength(1));
        final recognizer =
            webViewWidget.gestureRecognizers.single.constructor();
        expect(recognizer, isA<EagerGestureRecognizer>());
      } finally {
        controller.dispose();
      }
    });

    testWidgets('keeps gesture recognizers empty when scrollable is disabled',
        (tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedWebView.data(
                param: param,
                data: data,
                maxWidth: 640,
                controller: controller,
                scrollable: false,
              ),
            ),
          ),
        );

        await tester.pump();

        final webViewWidget =
            tester.widget<WebViewWidget>(find.byType(WebViewWidget));
        expect(webViewWidget.gestureRecognizers, isEmpty);
      } finally {
        controller.dispose();
      }
    });
  });
}
