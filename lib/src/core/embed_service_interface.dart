import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/core/embed_renderer.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/models/params/base_embed_params.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:http/http.dart' as http;

/// Interface for the embed service responsible for discovery and data fetching.
abstract class IEmbedService {
  /// Fetches OEmbed data using [param] and [config].
  Future<EmbedData> getResult({
    required EmbedLoaderParam param,
    EmbedConfig? config,
    EmbedLogger? logger,
    EmbedCacheConfig? cacheConfig,
    http.Client? httpClient,
  });

  /// Resolves the appropriate [BaseEmbedApi] for the given [param].
  BaseEmbedApi getEmbedApiByEmbedType(
    EmbedLoaderParam param, {
    EmbedLogger? logger,
  });

  /// Resolves the cache request URI used for a given content [url].
  Uri? resolveCacheUri(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    double? width,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
    EmbedLogger? logger,
  });

  /// Resolves how to render [url] given [config], returning an [EmbedRenderer].
  EmbedRenderer resolveRender(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
  });

  /// Resolves the [EmbedProviderRule] for a given [url] and [config].
  EmbedProviderRule? resolveRule(
    String url, {
    EmbedConfig? config,
  });

  /// Resolves the iframe URL for a given content URL if iframe mode is active.
  String? resolveIframeUrl(
    String url, {
    EmbedConfig? config,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    bool silent = false,
  });
}
