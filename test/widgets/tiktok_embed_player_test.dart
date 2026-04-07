import 'package:flutter/material.dart';
import 'package:flutter_embed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
import 'package:flutter_embed/src/models/tiktok_embed_params.dart';
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

  group('TikTokEmbedPlayer', () {
    testWidgets('should correctly extract the videoId from a raw ID string',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TikTokEmbedPlayer(
              videoIdOrUrl: '12345',
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.url, contains('/12345'));
    });

    testWidgets('should use embedParams to construct the player URL',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TikTokEmbedPlayer(
              videoIdOrUrl: '123',
              embedParams: TikTokEmbedParams(
                autoplay: true,
                controls: false,
              ),
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.url, contains('autoplay=1'));
      expect(webView.url, contains('controls=0'));
    });

    testWidgets('should respect individual player configuration parameters',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TikTokEmbedPlayer(
              videoIdOrUrl: '123',
              autoplay: true,
              controls: false,
              loop: true,
              musicInfo: true,
              description: true,
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.url, contains('autoplay=1'));
      expect(webView.url, contains('controls=0'));
      expect(webView.url, contains('loop=1'));
      expect(webView.url, contains('music_info=1'));
      expect(webView.url, contains('description=1'));
    });

    testWidgets('should not crash when the player is disposed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TikTokEmbedPlayer(videoIdOrUrl: '123'),
          ),
        ),
      );

      await tester.pump();
      // Should not crash on dispose
      await tester.pumpWidget(const SizedBox());
    });
  });
}
