import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/utils/embed_type_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedTypeExtension', () {
    test('svgIconUrl', () {
      expect(EmbedType.x.svgIconUrl, contains('x.svg'));
      expect(EmbedType.tiktok.svgIconUrl, contains('tiktok.svg'));
      expect(EmbedType.instagram.svgIconUrl, contains('instagram.svg'));
      expect(EmbedType.facebook.svgIconUrl, contains('facebook.svg'));
      expect(EmbedType.youtube.svgIconUrl, isEmpty);
    });

    test('displayName', () {
      expect(EmbedType.x.displayName, equals('X'));
      expect(EmbedType.youtube.displayName, equals('YouTube'));
      expect(EmbedType.giphy.displayName, equals('GIPHY'));
    });

    test('isMeta', () {
      expect(EmbedType.facebook.isMeta, isTrue);
      expect(EmbedType.instagram.isMeta, isTrue);
      expect(EmbedType.youtube.isMeta, isFalse);
    });
  });
}
