import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/widgets/embed_card.dart';
import 'package:flutter_oembed/src/widgets/embed_data_loader.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';

class MockHttpClient extends Mock implements http.Client {}

/// Integration test that validates the full resolve→fetch→render pipeline.
///
/// Uses a mock HTTP client (no real network) and [FakeWebViewPlatform] to
/// exercise the end-to-end flow: provider resolution, API call construction,
/// response parsing, widget tree assembly.
void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    WebViewPlatform.instance = FakeWebViewPlatform();
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
  });

  group('Pipeline integration', () {
    // -----------------------------------------------------------------------
    // Positive path: X (Twitter) embed resolves, fetches, and renders
    // -----------------------------------------------------------------------
    testWidgets('X embed: resolve → fetch → render', (tester) async {
      const xUrl = 'https://twitter.com/flutter/status/1234567890';

      // Step 1: Verify provider resolution (pure Dart, no Widget)
      final rule = EmbedService.resolveRule(xUrl);
      expect(rule, isNotNull);
      expect(rule!.providerName, 'X');

      // Step 2: Mock the OEmbed API response
      final oembedJson = jsonEncode({
        'html': '<blockquote>Hello from X</blockquote>',
        'type': 'rich',
        'provider_name': 'Twitter',
        'title': 'A tweet',
        'cache_age': '3600',
      });
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(oembedJson, 200));

      final config = EmbedConfig(
        httpClient: mockClient,
        cache: const EmbedCacheConfig(enabled: false),
      );

      // Step 3: Pump the full widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: config,
            child: Scaffold(
              body: EmbedCard.url(xUrl),
            ),
          ),
        ),
      );

      // Step 4: Should show loading state initially
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Step 5: After data arrives, should show EmbedWebView
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Verify the API was called once
      verify(() => mockClient.get(any(), headers: any(named: 'headers')))
          .called(1);

      // Verify EmbedWebView is in the tree
      expect(find.byType(EmbedWebView), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Negative path: 404 → error widget
    // -----------------------------------------------------------------------
    testWidgets('404 response renders error widget', (tester) async {
      const xUrl = 'https://twitter.com/user/status/9999999';

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final config = EmbedConfig(
        httpClient: mockClient,
        cache: const EmbedCacheConfig(enabled: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: config,
            child: Scaffold(
              body: EmbedCard.url(xUrl),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Should show error state (Icon widget with error icon)
      expect(find.byType(Icon), findsWidgets);
      // Should NOT show EmbedWebView
      expect(find.byType(EmbedWebView), findsNothing);
    });

    // -----------------------------------------------------------------------
    // YouTube provider resolution (iframe mode via registry)
    // -----------------------------------------------------------------------
    testWidgets('YouTube URL resolves correctly via registry', (tester) async {
      const ytUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

      final rule = EmbedService.resolveRule(ytUrl);
      expect(rule, isNotNull);
      expect(rule!.providerName, 'YouTube');

      // Verify iframe URL builder is present
      expect(rule.iframeUrlBuilder, isNotNull);
      final iframeUrl = rule.iframeUrlBuilder!(ytUrl);
      expect(iframeUrl, isNotNull);
      expect(iframeUrl, contains('youtube-nocookie.com/embed/dQw4w9WgXcQ'));
    });

    // -----------------------------------------------------------------------
    // Unrecognized URL => no provider found
    // -----------------------------------------------------------------------
    test('unrecognized URL resolves to null', () {
      final rule = EmbedService.resolveRule('https://unknown-site.com/abc');
      expect(rule, isNull);
    });

    // -----------------------------------------------------------------------
    // Multiple embeds in a list
    // -----------------------------------------------------------------------
    testWidgets('multiple EmbedCards render independently', (tester) async {
      final oembedJson = jsonEncode({
        'html': '<blockquote>Content</blockquote>',
        'type': 'rich',
      });
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(oembedJson, 200));

      final config = EmbedConfig(
        httpClient: mockClient,
        cache: const EmbedCacheConfig(enabled: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: config,
            child: Scaffold(
              body: ListView(
                children: [
                  EmbedCard.url('https://twitter.com/a/status/1'),
                  EmbedCard.url('https://twitter.com/b/status/2'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // Both should start loading
      expect(find.byType(EmbedDataLoader), findsNWidgets(2));

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Both should resolve
      expect(find.byType(EmbedWebView), findsNWidgets(2));
    });
  });
}
