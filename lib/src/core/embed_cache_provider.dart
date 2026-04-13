import 'dart:typed_data';

/// Interface for OEmbed response caching.
///
/// Implement this class to provide a custom caching strategy.
abstract class EmbedCacheProvider {
  /// Returns a cache provider that does nothing.
  ///
  /// Use this to disable caching for a scope or request config:
  /// ```dart
  /// EmbedConfig(cacheProvider: EmbedCacheProvider.never());
  /// ```
  factory EmbedCacheProvider.never() => const _NeverEmbedCacheProvider();

  /// Fetches a cached response by key.
  Future<Uint8List?> getFileFromCache(String key);

  /// Saves a response to the cache.
  Future<void> putFile(String key, Uint8List bytes, {Duration? maxAge});

  /// Clears the entire cache.
  Future<void> emptyCache();

  /// Removes a single cached entry by key.
  Future<void> removeFile(String key);
}

class _NeverEmbedCacheProvider implements EmbedCacheProvider {
  const _NeverEmbedCacheProvider();

  @override
  Future<Uint8List?> getFileFromCache(String key) async => null;

  @override
  Future<void> putFile(String key, Uint8List bytes, {Duration? maxAge}) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> removeFile(String key) async {}
}
