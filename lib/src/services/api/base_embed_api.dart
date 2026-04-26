import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_constant.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/cache/in_memory_cache_provider.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:http/http.dart' as http;

/// Base class for all OEmbed API clients.
///
/// Subclasses implement [constructUrl] and [handleErrorResponse] to provide
/// provider-specific behaviour. The [getEmbedData] method handles caching
/// and HTTP execution, so subclasses rarely need to override it.
abstract class BaseEmbedApi {
  const BaseEmbedApi();

  /// The base URL of the provider's OEmbed endpoint.
  String get baseUrl;

  /// Constructs the full request [Uri] for [url].
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    Map<String, String>? queryParameters,
    EmbedConfig? config,
  });

  /// Optional HTTP headers to include with every request.
  ///
  /// Defaults to include a standard `User-Agent` to avoid bot-blocking.
  Map<String, String> get headers => {
        'User-Agent': 'flutter_oembed/1.0',
        'Accept': 'application/json',
      };

  /// Called after a successful API response.
  ///
  /// Use this to normalise or post-process the [EmbedData] before caching.
  EmbedData oembedResponseModifier(EmbedData response) => response;

  // ---------------------------------------------------------------------------
  // Caching helpers — override to inject a custom cache manager in tests.
  // ---------------------------------------------------------------------------

  Future<EmbedData?> getCachedResult(
    Uri uri, {
    EmbedCacheProvider? cacheProvider,
    EmbedLogger? logger,
  }) async {
    try {
      final bytes = await _resolveCacheProvider(cacheProvider).getFileFromCache(
        uri.toString(),
      );
      if (bytes != null) {
        logger?.debug('Cache hit', data: {'uri': uri.toString()});
        return EmbedData.fromJson(jsonDecode(utf8.decode(bytes)));
      }
      logger?.debug('Cache miss', data: {'uri': uri.toString()});
      return null;
    } catch (error, stackTrace) {
      logger?.debug(
        'Failed to read cache',
        data: {'uri': uri.toString()},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> setCachedResult(
    Uri uri,
    EmbedData oembedData, {
    EmbedCacheProvider? cacheProvider,
    Duration? maxAge,
    EmbedLogger? logger,
  }) async {
    try {
      final resolvedMaxAge = maxAge ??
          oembedData.cacheAgeDuration ??
          kDefaultEmbedHtmlCacheLifeSpan;
      await _resolveCacheProvider(cacheProvider).putFile(
        uri.toString(),
        Uint8List.fromList(jsonEncode(oembedData.toJson()).codeUnits),
        maxAge: resolvedMaxAge,
      );
      logger?.debug('Cached OEmbed response', data: {
        'uri': uri.toString(),
        'ttl': resolvedMaxAge.toString(),
      });
    } catch (error, stackTrace) {
      logger?.debug(
        'Failed to write cache',
        data: {'uri': uri.toString()},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Builds the correct [Exception] from an HTTP error [response].
  Exception handleErrorResponse(http.Response response);

  /// Fetches OEmbed data for [url], using the cache when available.
  Future<EmbedData> getEmbedData(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    EmbedCacheProvider? cacheProvider,
    EmbedCacheConfig? cacheConfig,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    http.Client? httpClient,
    EmbedConfig? config,
  }) async {
    final resolvedConfig = config ?? const EmbedConfig();
    final resolvedCacheConfig = cacheConfig ?? resolvedConfig.cache;
    final resolvedCacheProvider = cacheProvider ?? resolvedConfig.cacheProvider;
    final resolvedLogger = logger ?? resolvedConfig.logger;
    final isInternalClient = httpClient == null;
    final client = httpClient ?? resolvedConfig.httpClient ?? http.Client();
    final uri = constructUrl(
      url,
      locale: locale,
      brightness: brightness,
      queryParameters: queryParameters,
      config: resolvedConfig,
    );
    resolvedLogger.debug('Resolving OEmbed request', data: {
      'url': url,
      'endpoint': uri.toString(),
    });

    if (resolvedCacheConfig.enabled) {
      final cached = await getCachedResult(
        uri,
        cacheProvider: resolvedCacheProvider,
        logger: resolvedLogger,
      );
      if (cached != null) {
        resolvedLogger.info('Using cached OEmbed response', data: {'url': url});
        return cached;
      }
    } else {
      resolvedLogger.debug('Cache disabled', data: {'url': url});
    }

    try {
      resolvedLogger.debug('Fetching OEmbed response from network', data: {
        'url': url,
        'uri': uri.toString(),
      });
      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        resolvedLogger.debug('OEmbed response received', data: {
          'url': url,
          'statusCode': response.statusCode,
          'body': response.body,
        });

        final decoded = oembedResponseModifier(
          EmbedData.fromJson(json.decode(response.body)),
        );

        if (resolvedCacheConfig.enabled) {
          final ttl = resolvedCacheConfig.resolve(decoded.cacheAgeDuration);
          await setCachedResult(
            uri,
            decoded,
            cacheProvider: resolvedCacheProvider,
            maxAge: ttl,
            logger: resolvedLogger,
          );
        }

        resolvedLogger.info('Fetched OEmbed response', data: {'url': url});
        return decoded;
      } else {
        resolvedLogger.warning(
          'OEmbed request failed',
          data: {
            'url': url,
            'statusCode': response.statusCode,
            'body': response.body,
          },
        );
        throw handleErrorResponse(response);
      }
    } finally {
      if (isInternalClient) {
        client.close();
      }
    }
  }

  @internal
  EmbedCacheProvider resolveCacheProvider([EmbedCacheProvider? cacheProvider]) {
    return _resolveCacheProvider(cacheProvider);
  }

  EmbedCacheProvider _resolveCacheProvider(EmbedCacheProvider? cacheProvider) {
    return cacheProvider ?? InMemoryEmbedCacheProvider.instance;
  }
}

// ---------------------------------------------------------------------------
// Generic implementation
// ---------------------------------------------------------------------------

/// A generic OEmbed API client that works with any standard OEmbed endpoint.
class GenericEmbedApi extends BaseEmbedApi {
  const GenericEmbedApi(
    this.endpoint, {
    Map<String, String>? headers,
    this.width,
  }) : _headers = headers ?? const {};

  final String endpoint;
  final Map<String, String> _headers;
  final double? width;

  @override
  String get baseUrl => endpoint.replaceAll('{format}', 'json');

  @override
  Map<String, String> get headers => _headers;

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    Map<String, String>? queryParameters,
    EmbedConfig? config,
  }) {
    final proxyUrl = config?.proxyUrl;
    final resolvedBaseUrl = proxyUrl != null ? '$proxyUrl/$baseUrl' : baseUrl;
    final uri = Uri.parse(resolvedBaseUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['url'] = url;
    // Always request JSON format unless specified otherwise
    params.putIfAbsent('format', () => 'json');

    if (width != null) {
      params['maxwidth'] = width!.toInt().toString();
    }

    if (queryParameters != null) {
      params.addAll(queryParameters);
    }

    return uri.replace(
      queryParameters: params,
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return const EmbedDataNotFoundException();
    return const EmbedApisException();
  }
}
