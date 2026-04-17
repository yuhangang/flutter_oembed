import 'dart:typed_data';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_oembed/src/cache/in_memory_cache_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryEmbedCacheProvider provider;

  setUp(() {
    provider = InMemoryEmbedCacheProvider();
  });

  group('InMemoryEmbedCacheProvider', () {
    test('stores and retrieves data', () async {
      final key = 'test_key';
      final data = Uint8List.fromList([1, 2, 3]);

      await provider.putFile(key, data);
      final result = await provider.getFileFromCache(key);

      expect(result, equals(data));
    });

    test('returns null for non-existent keys', () async {
      final result = await provider.getFileFromCache('missing');
      expect(result, isNull);
    });

    test('removes data', () async {
      final key = 'test_key';
      final data = Uint8List.fromList([1, 2, 3]);

      await provider.putFile(key, data);
      await provider.removeFile(key);
      final result = await provider.getFileFromCache(key);

      expect(result, isNull);
    });

    test('clears entire cache', () async {
      await provider.putFile('k1', Uint8List(0));
      await provider.putFile('k2', Uint8List(0));

      await provider.emptyCache();

      expect(await provider.getFileFromCache('k1'), isNull);
      expect(await provider.getFileFromCache('k2'), isNull);
    });

    test('respects maxAge (TTL)', () {
      fakeAsync((async) {
        withClock(async.getClock(DateTime(2023, 1, 1)), () {
          final key = 'test_key';
          final data = Uint8List.fromList([1, 2, 3]);
          final maxAge = const Duration(minutes: 5);

          provider.putFile(key, data, maxAge: maxAge);

          // Advance time just before expiration
          async.elapse(const Duration(minutes: 4, seconds: 59));

          // Should still be there
          provider.getFileFromCache(key).then((result) {
            expect(result, equals(data));
          });

          // Advance time past expiration
          async.elapse(const Duration(seconds: 2));

          // Should be gone
          provider.getFileFromCache(key).then((result) {
            expect(result, isNull);
          });

          async.flushMicrotasks();
        });
      });
    });

    test('singleton instance is shared', () {
      expect(
        InMemoryEmbedCacheProvider.instance,
        same(InMemoryEmbedCacheProvider.instance),
      );
    });
  });
}
