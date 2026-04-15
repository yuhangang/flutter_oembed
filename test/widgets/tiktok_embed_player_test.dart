import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/models/tiktok_embed_params.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../fake_webview_platform.dart';

EmbedController buildController({SocialEmbedParam? param}) {
  final controller = EmbedController();
  if (param != null) {
    controller.synchronize(contentKey: param);
  }
  return controller;
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
      expect(webView.data?.html, contains('/12345'));
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
      expect(webView.data?.html, contains('autoplay=1'));
      expect(webView.data?.html, contains('controls=0'));
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
              progressBar: false,
              playButton: false,
              volumeControl: false,
              fullscreenButton: false,
              timestamp: false,
              rel: false,
              nativeContextMenu: false,
              closedCaption: false,
              muted: true,
            ),
          ),
        ),
      );

      final webView = tester.widget<EmbedWebView>(find.byType(EmbedWebView));
      expect(webView.data?.html, contains('autoplay=1'));
      expect(webView.data?.html, contains('controls=0'));
      expect(webView.data?.html, contains('loop=1'));
      expect(webView.data?.html, contains('music_info=1'));
      expect(webView.data?.html, contains('description=1'));
      expect(webView.data?.html, contains('progress_bar=0'));
      expect(webView.data?.html, contains('play_button=0'));
      expect(webView.data?.html, contains('volume_control=0'));
      expect(webView.data?.html, contains('fullscreen_button=0'));
      expect(webView.data?.html, contains('timestamp=0'));
      expect(webView.data?.html, contains('rel=0'));
      expect(webView.data?.html, contains('native_context_menu=0'));
      expect(webView.data?.html, contains('closed_caption=0'));
      expect(webView.data?.html, contains('muted=1'));
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

    testWidgets(
        'recreates the inner WebView when embed params change without a manual key',
        (tester) async {
      final controller = buildController(
        param: SocialEmbedParam(
          url: 'https://www.tiktok.com/@user/video/123',
          embedType: EmbedType.tiktok_v1,
        ),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TikTokEmbedPlayer(
                videoIdOrUrl: '123',
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
          fakePlatform.lastCreatedController?.lastLoadedHtml,
          contains('controls=1'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TikTokEmbedPlayer(
                videoIdOrUrl: '123',
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
      } finally {
        controller.dispose();
      }
    });
  });
}
