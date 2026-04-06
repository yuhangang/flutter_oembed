import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/utils/embed_html_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loadEmbedHtmlDocument', () {
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
