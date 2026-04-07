import 'package:flutter_embed/src/utils/embed_scheme_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedSchemeUtils', () {
    test('oembedSchemeToPattern protocols', () {
      expect(oembedSchemeToPattern('https://test.com/*'), startsWith('^https?:\\/\\/test\\.com\\/.*'));
      expect(oembedSchemeToPattern('http://test.com/*'), startsWith('^https?:\\/\\/test\\.com\\/.*'));
      expect(oembedSchemeToPattern('//test.com/*'), startsWith('^https?:\\/\\/test\\.com\\/.*'));
    });
  });
}
