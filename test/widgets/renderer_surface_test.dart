import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/widgets/embed_renderer.dart';
import 'package:flutter_embed/src/widgets/embed_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../fake_webview_platform.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('EmbedRenderer', () {
    testWidgets('maxWidth and config integration', (tester) async {
      final data = EmbedData(html: '<div>Test</div>');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedScope(
              config: const EmbedConfig(scrollable: true),
              child: EmbedRenderer(
                data: data,
                embedType: EmbedType.other,
                maxWidth: 300,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) => widget is ConstrainedBox && widget.constraints.maxWidth == 300,
      );
      expect(constrainedBoxFinder, findsOneWidget);
      
      // Clear timers from WebView
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('handles null providerUrl', (tester) async {
      final data = EmbedData(html: '<div>Test</div>', providerUrl: null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedRenderer(
              data: data,
              embedType: EmbedType.other,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(EmbedSurface), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
    });
  });

  group('EmbedSurface', () {
    testWidgets('fallbackWrapperBuilder and borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmbedSurface(
            childBuilder: (context) => const Text('Child'),
            fallbackWrapperBuilder: (context, child) => Container(key: const Key('wrapper'), child: child),
          ),
        ),
      );

      expect(find.byKey(const Key('wrapper')), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedSurface(
            childBuilder: (context) => const Text('Child'),
            style: EmbedStyle(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('footerBuilder in style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmbedSurface(
            childBuilder: (context) => const Text('Child'),
            style: EmbedStyle(
              footerBuilder: (context, url) => Text('Footer: $url', key: const Key('footer')),
            ),
            footerUrl: 'https://example.com',
          ),
        ),
      );

      expect(find.byKey(const Key('footer')), findsOneWidget);
      expect(find.text('Footer: https://example.com'), findsOneWidget);
    });
  });
}
