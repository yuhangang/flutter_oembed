import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:oembed/src/models/embed_constant.dart';
import 'package:oembed/src/models/oembed_cache_config.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:oembed/src/logging/oembed_logger.dart';
import 'package:oembed/src/utils/embed_errors.dart';

/// Base class for all OEmbed API clients.
///
/// Subclasses implement [constructUrl] and [handleErrorResponse] to provide
/// provider-specific behaviour. The [getOembedData] method handles caching
/// and HTTP execution, so subclasses rarely need to override it.
abstract class BaseOembedApi {
  const BaseOembedApi();

  /// The base URL of the provider's OEmbed endpoint.
  String get baseUrl;

  /// Constructs the full request [Uri] for [url].
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  });

  /// Optional HTTP headers to include with every request.
  Map<String, String> get headers => {};

  /// Called after a successful API response.
  ///
  /// Use this to normalise or post-process the [OembedData] before caching.
  OembedData ombedResponseModifier(OembedData response) => response;

  // ---------------------------------------------------------------------------
  // Caching helpers — override to inject a custom cache manager in tests.
  // ---------------------------------------------------------------------------

  BaseCacheManager get _cacheManager => DefaultCacheManager();

  Future<OembedData?> getCachedResult(Uri uri, {OembedLogger? logger}) async {
    try {
      final cache = await _cacheManager.getFileFromCache(uri.toString());
      final bytes = await cache?.file.readAsBytes();
      if (bytes != null) {
        logger?.debug('Cache hit for $uri');
        return OembedData.fromJson(jsonDecode(utf8.decode(bytes)));
      }
      logger?.debug('Cache miss for $uri');
      return null;
    } catch (error, stackTrace) {
      logger?.debug(
        'Failed to read cache for $uri',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> setCachedResult(
    Uri uri,
    OembedData oembedData, {
    Duration? maxAge,
    OembedLogger? logger,
  }) async {
    try {
      final resolvedMaxAge =
          maxAge ??
          oembedData.cacheAgeDuration ??
          kDefaultEmbedHtmlCacheLifeSpan;
      await _cacheManager.putFile(
        uri.toString(),
        Uint8List.fromList(jsonEncode(oembedData.toJson()).codeUnits),
        maxAge: resolvedMaxAge,
      );
      logger?.debug('Cached OEmbed response for $uri (ttl: $resolvedMaxAge)');
    } catch (error, stackTrace) {
      logger?.debug(
        'Failed to write cache for $uri',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Builds the correct [Exception] from an HTTP error [response].
  Exception handleErrorResponse(http.Response response);

  /// Fetches OEmbed data for [url], using the cache when available.
  Future<OembedData> getOembedData(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    OembedCacheConfig? cacheConfig,
    OembedLogger? logger,
  }) async {
    final config = cacheConfig ?? const OembedCacheConfig();
    final uri = constructUrl(url, locale: locale, brightness: brightness);
    logger?.debug('Resolving OEmbed request for $url -> $uri');

    if (config.enabled) {
      final cached = await getCachedResult(uri, logger: logger);
      if (cached != null) {
        logger?.info('Using cached OEmbed response for $url');
        return cached;
      }
    } else {
      logger?.debug('Cache disabled for $url');
    }

    logger?.debug('Fetching OEmbed response from network: $uri');
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decoded = ombedResponseModifier(
        OembedData.fromJson(json.decode(response.body)),
      );

      if (config.enabled) {
        final ttl = config.resolve(decoded.cacheAgeDuration);
        await setCachedResult(uri, decoded, maxAge: ttl, logger: logger);
      }

      logger?.info('Fetched OEmbed response for $url');
      return decoded;
    } else {
      logger?.warning(
        'OEmbed request failed for $url with status ${response.statusCode}',
      );
      throw handleErrorResponse(response);
    }
  }
}

// ---------------------------------------------------------------------------
// Generic implementation
// ---------------------------------------------------------------------------

/// A generic OEmbed API client that works with any standard OEmbed endpoint.
class GenericOembedApi extends BaseOembedApi {
  const GenericOembedApi(
    this.endpoint, {
    Map<String, String>? headers,
    this.width,
    this.proxyUrl,
  }) : _headers = headers ?? const {};

  final String endpoint;
  final String? proxyUrl;
  final Map<String, String> _headers;
  final double? width;

  @override
  String get baseUrl {
    final resolved = endpoint.replaceAll('{format}', 'json');
    return proxyUrl != null ? '$proxyUrl/$resolved' : resolved;
  }

  @override
  Map<String, String> get headers => _headers;

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) {
    return Uri.parse(baseUrl).replace(
      queryParameters: {
        'url': url,
        if (width != null) 'maxwidth': width!.toInt().toString(),
      },
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
