import 'dart:typed_data';
import 'package:clock/clock.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';

/// Lightweight in-memory implementation of [EmbedCacheProvider].
///
/// Use this for transient caching that does not persist across app restarts.
class InMemoryEmbedCacheProvider implements EmbedCacheProvider {
  /// Global singleton instance.
  static final InMemoryEmbedCacheProvider instance =
      InMemoryEmbedCacheProvider();

  final Map<String, _CacheEntry> _cache = {};

  InMemoryEmbedCacheProvider();

  @override
  Future<Uint8List?> getFileFromCache(String key) async {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.bytes;
  }

  @override
  Future<void> putFile(String key, Uint8List bytes, {Duration? maxAge}) async {
    _cache[key] = _CacheEntry(
      bytes: bytes,
      timestamp: clock.now(),
      maxAge: maxAge ?? const Duration(days: 30),
    );
  }

  @override
  Future<void> emptyCache() async {
    _cache.clear();
  }

  @override
  Future<void> removeFile(String key) async {
    _cache.remove(key);
  }
}

class _CacheEntry {
  final Uint8List bytes;
  final DateTime timestamp;
  final Duration maxAge;

  _CacheEntry({
    required this.bytes,
    required this.timestamp,
    required this.maxAge,
  });

  bool get isExpired => clock.now().difference(timestamp) > maxAge;
}
