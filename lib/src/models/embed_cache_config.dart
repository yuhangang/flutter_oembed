/// Configuration for OEmbed response caching.
class EmbedCacheConfig {
  /// Whether caching is enabled. When false, every request hits the network.
  final bool enabled;

  /// Default cache duration, used when [respectApiCacheAge] is false or the
  /// API doesn't return a `cache_age` value.
  final Duration defaultCacheDuration;

  /// When true, the `cache_age` value from the OEmbed API response is used
  /// as the cache TTL. Falls back to [defaultCacheDuration] when absent.
  final bool respectApiCacheAge;

  /// Optional upper bound on the cache duration. Useful to force periodic
  /// refreshes even when the API returns a very large `cache_age`.
  final Duration? maxCacheDuration;

  const EmbedCacheConfig({
    this.enabled = true,
    this.defaultCacheDuration = const Duration(days: 7),
    this.respectApiCacheAge = true,
    this.maxCacheDuration,
  });

  /// Resolves the cache duration for a given OEmbed [cacheAgeDuration] from
  /// the API response.
  Duration resolve(Duration? cacheAgeDuration) {
    Duration duration = defaultCacheDuration;

    if (respectApiCacheAge && cacheAgeDuration != null) {
      duration = cacheAgeDuration;
    }

    if (maxCacheDuration != null && duration > maxCacheDuration!) {
      duration = maxCacheDuration!;
    }

    return duration;
  }
}
