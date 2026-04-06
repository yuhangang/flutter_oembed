import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/utils/embed_matchers.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';

void main() {
  group('GIPHY Matchers', () {
    test('matches giphy.com/gifs URLs', () {
      expect(
        EmbedMatchers.getEmbedType('https://giphy.com/gifs/cat-123'),
        EmbedType.giphy,
      );
    });

    test('matches giphy.com/clips URLs', () {
      expect(
        EmbedMatchers.getEmbedType('https://giphy.com/clips/cat-123'),
        EmbedType.giphy,
      );
    });

    test('matches gph.is URLs', () {
      expect(
        EmbedMatchers.getEmbedType('http://gph.is/123'),
        EmbedType.giphy,
      );
    });

    test('matches media.giphy.com URLs', () {
      expect(
        EmbedMatchers.getEmbedType('https://media.giphy.com/media/123/giphy.gif'),
        EmbedType.giphy,
      );
    });
  });
}
