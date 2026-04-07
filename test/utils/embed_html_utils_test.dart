import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/utils/embed_html_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loadEmbedHtmlDocument', () {
    test('X (Twitter) document', () {
      final doc = loadEmbedHtmlDocument('<div>X</div>', type: EmbedType.x, maxWidth: 640);
      expect(doc, contains('<div>X</div>'));
      expect(doc, contains('overflow: hidden;'));
    });

    test('TikTok document', () {
      final doc = loadEmbedHtmlDocument('<blockquote>TikTok</blockquote>', type: EmbedType.tiktok, maxWidth: 640);
      expect(doc, contains('blockquote.tiktok-embed'));
      expect(doc, contains('window.tiktok.embed()'));
    });

    test('Facebook video document', () {
      final doc = loadEmbedHtmlDocument('<iframe>FB</iframe>', type: EmbedType.facebook_video, maxWidth: 640);
      expect(doc, isNot(contains('background-color: white;')));
    });

    test('Reddit document', () {
      final doc = loadEmbedHtmlDocument('<blockquote>Reddit</blockquote>', type: EmbedType.reddit, maxWidth: 640);
      expect(doc, contains('id="reddit-container"'));
    });

    test('Other document with scrollable enabled', () {
      final doc = loadEmbedHtmlDocument('<div>Other</div>', type: EmbedType.other, maxWidth: 640, scrollable: true);
      expect(doc, isNot(contains('overflow: hidden;')));
    });

    test('sanitizes YouTube iframe params for WebView embeds', () {
      const html = '''
<iframe
  src="https://www.youtube.com/embed/dQw4w9WgXcQ?enablejsapi=1&origin=https://www.youtube.com"
  allowfullscreen>
</iframe>
''';

      final document = loadEmbedHtmlDocument(
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
      expect(
          document, contains('widget_referrer=https%3A%2F%2Fwww.youtube-nocookie.com'));
      expect(document, contains('enablejsapi=1'));
      expect(document, contains('origin=https%3A%2F%2Fwww.youtube-nocookie.com'));
    });
  });
}
