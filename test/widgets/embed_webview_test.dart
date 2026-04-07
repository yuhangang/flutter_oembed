import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../fake_webview_platform.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('EmbedWebView', () {
    late EmbedController controller;
    late SocialEmbedParam param;
    late EmbedData data;

    setUp(() {
      param = SocialEmbedParam(
        url: 'https://youtube.com/watch?v=123',
        embedType: EmbedType.youtube,
      );
      controller = EmbedController(param: param);
      data = EmbedData(html: '<div>Test</div>');
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

    testWidgets('should trigger re-initialization when didUpdateWidget is called',
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
              webViewBuilder: (context, child) =>
                  Container(key: const Key('custom'), child: child),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom')), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('should allow retry logic when the controller is in an error state',
        (tester) async {
      controller.setLoadingState(EmbedLoadingState.error);

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
      final refreshIcon = find.byIcon(Icons.refresh);
      expect(refreshIcon, findsOneWidget);

      await tester.tap(refreshIcon);
      expect(controller.loadingState, EmbedLoadingState.loading);
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('should trigger re-initialization when a new controller is provided',
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

      final newController = EmbedController(param: param);

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
  });
}
