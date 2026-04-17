import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/widgets/youtube_embed_player.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../fake_webview_platform.dart';

void main() {
  final fakePlatform = FakeWebViewPlatform();

  setUpAll(() {
    WebViewPlatform.instance = fakePlatform;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() {
    fakePlatform.reset();
  });

  group('YoutubeEmbedPlayer', () {
    testWidgets('should correctly extract the videoId from a raw ID string',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YoutubeEmbedPlayer(
              videoIdOrUrl: 'dQw4w9WgXcQ',
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.data?.html, contains('dQw4w9WgXcQ'));
    });

    testWidgets('should apply the custom theme, color, and loop parameters',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YoutubeEmbedPlayer(
              videoIdOrUrl: 'dQw4w9WgXcQ',
              theme: 'light',
              color: 'white',
              loop: true,
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.data?.html, contains('"theme":"light"'));
      expect(webView.data?.html, contains('"color":"white"'));
      expect(webView.data?.html, contains('"loop":1'));
      expect(webView.data?.html, contains('"playlist":"dQw4w9WgXcQ"'));
    });

    testWidgets(
        'should use a dark theme and custom experimental origin when configured',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EmbedScope(
            config: EmbedConfig(brightness: Brightness.dark),
            child: Scaffold(
              body: YoutubeEmbedPlayer(
                videoIdOrUrl: 'dQw4w9WgXcQ',
                useOriginExperiment: true,
                experimentalOrigin: 'https://custom.origin',
              ),
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.data?.html, contains('"theme":"dark"'));
      expect(webView.data?.providerUrl, equals('https://custom.origin'));
    });
  });
}
