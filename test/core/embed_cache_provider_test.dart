import 'dart:typed_data';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedCacheProvider.never()', () {
    test('getFileFromCache always returns null', () async {
      final provider = EmbedCacheProvider.never();
      final result = await provider.getFileFromCache('key');
      expect(result, isNull);
    });

    test('putFile completes successfully without doing anything', () async {
      final provider = EmbedCacheProvider.never();
      await expectLater(
        provider.putFile('key', Uint8List(0)),
        completes,
      );
    });

    test('emptyCache completes successfully without doing anything', () async {
      final provider = EmbedCacheProvider.never();
      await expectLater(
        provider.emptyCache(),
        completes,
      );
    });

    test('removeFile completes successfully without doing anything', () async {
      final provider = EmbedCacheProvider.never();
      await expectLater(
        provider.removeFile('key'),
        completes,
      );
    });

    test('identity is consistent', () {
      final p1 = EmbedCacheProvider.never();
      final p2 = EmbedCacheProvider.never();
      // Since it's a const constructor in the factory, they should be identical
      expect(p1, same(p2));
    });
  });
}
