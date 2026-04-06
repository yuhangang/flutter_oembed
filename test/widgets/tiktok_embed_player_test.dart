import 'package:flutter/material.dart';
import 'package:flutter_embed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
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
    testWidgets('renders EmbedWebView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TikTokEmbedPlayer(
              videoIdOrUrl: 'https://www.tiktok.com/@scout2015/video/6718335390845095173',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(EmbedWebView), findsOneWidget);
    });
  });
}
