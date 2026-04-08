import 'package:flutter_oembed/src/core/provider_strategies.dart';
import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // HTML document generation is now delegated to each EmbedProviderStrategy.
  // These tests verify each strategy produces the correct HTML wrapper.
  group('EmbedProviderStrategy.buildHtmlDocument', () {
    test('XProviderStrategy wraps embed in a div', () {
      const strategy = XProviderStrategy();
      final doc = strategy.buildHtmlDocument(
        '<div>X</div>',
        type: EmbedType.x,
        maxWidth: 640,
      );
      expect(doc, contains('<div>X</div>'));
      expect(doc, contains('overflow: hidden;'));
    });

    test('TikTokProviderStrategy includes tiktok-embed styles and script', () {
      const strategy = TikTokProviderStrategy();
      final doc = strategy.buildHtmlDocument(
        '<blockquote>TikTok</blockquote>',
        type: EmbedType.tiktok,
        maxWidth: 640,
      );
      expect(doc, contains('blockquote.tiktok-embed'));
      expect(doc, contains('window.tiktok.embed()'));
    });

    test('MetaProviderStrategy (facebook_video) omits white background', () {
      const strategy = MetaProviderStrategy(EmbedType.facebook_video);
      final doc = strategy.buildHtmlDocument(
        '<iframe>FB</iframe>',
        type: EmbedType.facebook_video,
        maxWidth: 640,
      );
      expect(doc, isNot(contains('background-color: white;')));
    });

    test('RedditProviderStrategy includes reddit-container div', () {
      const strategy = RedditProviderStrategy();
      final doc = strategy.buildHtmlDocument(
        '<blockquote>Reddit</blockquote>',
        type: EmbedType.reddit,
        maxWidth: 640,
      );
      expect(doc, contains('id="reddit-container"'));
    });

    test(
        'GenericEmbedProviderStrategy with scrollable=true omits overflow hidden',
        () {
      const strategy = GenericEmbedProviderStrategy();
      final doc = strategy.buildHtmlDocument(
        '<div>Other</div>',
        type: EmbedType.other,
        maxWidth: 640,
        scrollable: true,
      );
      expect(doc, isNot(contains('overflow: hidden;')));
    });

    test('GenericEmbedProviderStrategy styles iframe correctly', () {
      const strategy = GenericEmbedProviderStrategy();
      final doc = strategy.buildHtmlDocument(
        '<iframe height="400"></iframe>',
        type: EmbedType.other,
        maxWidth: 640,
      );
      expect(doc, contains('iframe {'));
      expect(doc, isNot(contains('iframe {\n      width: 100% !important;\n      height: auto !important;')));
      expect(doc, contains('border: none;'));
      expect(doc, contains('width: 100% !important;'));
    });

    test('YouTubeProviderStrategy sanitizes iframe params for WebView embeds',
        () {
      const html = '''
<iframe
  src="https://www.youtube.com/embed/dQw4w9WgXcQ?enablejsapi=1&origin=https://www.youtube.com"
  allowfullscreen>
</iframe>
''';

      const strategy = YouTubeProviderStrategy();
      final document = strategy.buildHtmlDocument(
        html,
        type: EmbedType.youtube,
        maxWidth: 640,
      );

      expect(
        document,
        contains(
          '<meta name="referrer" content="strict-origin-when-cross-origin">',
        ),
      );
      expect(
        document,
        contains('referrerpolicy="strict-origin-when-cross-origin"'),
      );
      expect(document, contains('playsinline=1'));
      expect(document,
          contains('widget_referrer=https%3A%2F%2Fwww.youtube-nocookie.com'));
      expect(document, contains('enablejsapi=1'));
      expect(
          document, contains('origin=https%3A%2F%2Fwww.youtube-nocookie.com'));
    });
  });
}
