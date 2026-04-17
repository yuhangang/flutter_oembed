import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/utils/embed_type_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedTypeExtension', () {
    test('displayName', () {
      expect(EmbedType.x.displayName, equals('X'));
      expect(EmbedType.youtube.displayName, equals('YouTube'));
      expect(EmbedType.giphy.displayName, equals('GIPHY'));
    });

    test('isMeta', () {
      expect(EmbedType.facebook.isMeta, isTrue);
      expect(EmbedType.instagram.isMeta, isTrue);
      expect(EmbedType.threads.isMeta, isTrue);
      expect(EmbedType.youtube.isMeta, isFalse);
    });
  });
}
