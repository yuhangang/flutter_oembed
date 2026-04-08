import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_provider_config.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
import 'package:flutter_embed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_embed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('EmbedWidgetLoader', () {
    testWidgets('shows EmbedWebView when preloadedData is provided',
        (tester) async {
      final data = const EmbedData(
        type: 'rich',
        html: '<div>Preloaded</div>',
      );
      final param = SocialEmbedParam(
        url: 'https://example.com',
        embedType: EmbedType.other,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWidgetLoader(
              param: param,
              preloadedData: data,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(EmbedWebView), findsOneWidget);
    });

    testWidgets('shows TikTokEmbedPlayer for TikTok v1', (tester) async {
      final param = SocialEmbedParam(
        url: 'https://www.tiktok.com/@user/video/123',
        embedType: EmbedType.tiktok_v1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWidgetLoader(
              param: param,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(TikTokEmbedPlayer), findsOneWidget);
    });

    testWidgets('didUpdateWidget replaces controller', (tester) async {
      final param1 = SocialEmbedParam(
          url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          embedType: EmbedType.youtube);
      final param2 = SocialEmbedParam(
          url: 'https://www.youtube.com/watch?v=L_jWHffIx5E',
          embedType: EmbedType.youtube);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWidgetLoader(param: param1),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedWidgetLoader(param: param2),
          ),
        ),
      );

      await tester.pump();
    });

    testWidgets('didChangeDependencies updates scopeConfig', (tester) async {
      final param = SocialEmbedParam(
          url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          embedType: EmbedType.youtube);

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: const EmbedConfig(facebookAppId: '1'),
            child: Scaffold(
              body: EmbedWidgetLoader(param: param),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: const EmbedConfig(facebookAppId: '2'),
            child: Scaffold(
              body: EmbedWidgetLoader(param: param),
            ),
          ),
        ),
      );

      await tester.pump();
    });

    testWidgets('shows EmbedWebView for iframe render mode', (tester) async {
      final param = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        embedType: EmbedType.youtube,
      );

      final config = const EmbedConfig(
        providers: EmbedProviderConfig(
          providerRenderModes: {'YouTube': EmbedRenderMode.iframe},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: config,
            child: Scaffold(
              body: EmbedWidgetLoader(
                param: param,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(EmbedWebView), findsOneWidget);
    });
  });
}
