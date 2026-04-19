import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/params/base_embed_params.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/configs/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/core/embed_renderer.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/core/embed_service_interface.dart';

/// Default implementation of [IEmbedService].
class EmbedServiceImpl implements IEmbedService {
  const EmbedServiceImpl();

  @override
  Future<EmbedData> getResult({
    required EmbedLoaderParam param,
    EmbedConfig? config,
    EmbedLogger? logger,
    EmbedCacheConfig? cacheConfig,
    http.Client? httpClient,
  }) async {
    final resolvedLogger =
        logger ?? config?.logger ?? const EmbedLogger.disabled();
    final resolvedCacheConfig = cacheConfig ?? config?.cache;
    final resolvedCacheProvider = config?.cacheProvider;
    final locale = config?.locale ?? 'en';
    final brightness = config?.brightness ?? Brightness.light;

    resolvedLogger.debug(
      'Loading embed data',
      data: {
        'url': param.url,
        'embedType': param.embedType.name,
      },
    );

    final api = resolveApi(
      param,
      config: config,
      logger: resolvedLogger,
    );

    return api.getEmbedData(
      param.url,
      locale: locale,
      brightness: brightness,
      cacheProvider: resolvedCacheProvider,
      cacheConfig: resolvedCacheConfig,
      logger: resolvedLogger,
      queryParameters: param.queryParameters,
      httpClient: httpClient,
    );
  }

  @override
  BaseEmbedApi getEmbedApiByEmbedType(
    EmbedLoaderParam param, {
    EmbedLogger? logger,
  }) {
    return resolveApi(param, logger: logger);
  }

  @override
  Uri? resolveCacheUri(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    double? width,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
    EmbedLogger? logger,
  }) {
    try {
      final param = EmbedLoaderParam(
        url: url,
        embedType: embedType ?? EmbedType.other,
        width: width ?? 0,
        queryParameters: queryParameters,
        embedParams: embedParams,
      );
      final api = resolveApi(param, config: config, logger: logger);
      return api.constructUrl(
        url,
        locale: config?.locale ?? 'en',
        brightness: config?.brightness ?? Brightness.light,
        queryParameters: queryParameters,
      );
    } on EmbedProviderNotFoundException {
      return null;
    }
  }

  @override
  EmbedRenderer resolveRender(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
  }) {
    final rule = resolveRule(url, config: config);
    if (rule != null) {
      final endpoint = rule.resolveEndpoint(url);
      final variant = rule.resolveVariant(
        url,
        embedParams: embedParams,
        embedType: embedType,
      );
      final capabilities = rule.resolveCapabilities(
        url,
        embedParams: embedParams,
        embedType: embedType,
      );

      // Resolve iframe URL if requested in config
      final iframeUrl = resolveIframeUrl(
        url,
        config: config,
        queryParameters: queryParameters,
        logger: logger,
        silent: true,
      );

      final ctx = EmbedProviderContext(
        url: url,
        resolvedEndpoint: endpoint,
        width: 0,
        locale: config?.locale ?? 'en',
        brightness: config?.brightness ?? Brightness.light,
        facebookAppId: config?.facebookAppId,
        facebookClientToken: config?.facebookClientToken,
        rule: rule,
        strategy: rule.strategy,
        providerName: rule.providerName,
        variant: variant,
        capabilities: capabilities,
        proxyUrl: config?.proxyUrl,
        embedParams: embedParams,
        iframeUrl: iframeUrl,
        embedType: embedType,
      );
      return rule.strategy.resolveRenderer(ctx, config: config);
    }

    // Default: OEmbed API fetch
    return const OEmbedRenderer();
  }

  @override
  EmbedProviderRule? resolveRule(
    String url, {
    EmbedConfig? config,
  }) {
    EmbedProviderRule? rule;

    // 1. Check EmbedProviderConfig rules first
    if (config != null) {
      rule = config.resolvedProviders.matchRule(url);
    } else {
      // Fallback for when no config is provided
      rule = EmbedProviders.verified.firstWhereOrNull(
        (r) => r.matches(url),
      );
    }
    return rule;
  }

  @override
  String? resolveIframeUrl(
    String url, {
    EmbedConfig? config,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    bool silent = false,
  }) {
    if (config == null) return null;
    final resolvedLogger = logger ?? config.logger;

    final rule = resolveRule(url, config: config);
    if (rule == null) {
      if (!silent) {
        resolvedLogger.debug('No iframe provider match', data: {'url': url});
      }
      return null;
    }

    final mode = config.resolvedProviders.getRenderMode(rule.providerName);
    if (mode != EmbedRenderMode.iframe) {
      if (!silent) {
        resolvedLogger.debug(
          'Rendering mode mismatch',
          data: {
            'url': url,
            'provider': rule.providerName,
            'configuredMode': mode.name,
            'requiredMode': 'iframe',
          },
        );
      }
      return null;
    }

    var iframeUrl = rule.iframeUrlBuilder?.call(url);
    if (iframeUrl != null) {
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final uri = Uri.parse(iframeUrl);
        final params = Map<String, dynamic>.from(uri.queryParameters);
        params.addAll(queryParameters);
        iframeUrl = uri.replace(queryParameters: params).toString();
      }
      resolvedLogger.debug('Resolved iframe URL', data: {
        'url': url,
        'iframeUrl': iframeUrl,
      });
    }
    return iframeUrl;
  }

  /// Internal helper to resolve the API for a given parameter.
  BaseEmbedApi resolveApi(
    EmbedLoaderParam param, {
    EmbedConfig? config,
    EmbedLogger? logger,
  }) {
    final resolvedLogger =
        logger ?? config?.logger ?? const EmbedLogger.disabled();
    final facebookAppId = config?.facebookAppId;
    final facebookClientToken = config?.facebookClientToken;
    final locale = config?.locale ?? 'en';
    final brightness = config?.brightness ?? Brightness.light;

    final rule = resolveRule(param.url, config: config);

    // 3. Resolve using found rule
    if (rule != null) {
      final endpoint = rule.resolveEndpoint(param.url);
      final variant = rule.resolveVariant(
        param.url,
        embedParams: param.embedParams,
        embedType: param.embedType,
      );
      final capabilities = rule.resolveCapabilities(
        param.url,
        embedParams: param.embedParams,
        embedType: param.embedType,
      );
      resolvedLogger.debug(
        'Matched provider',
        data: {
          'url': param.url,
          'provider': rule.providerName,
          'endpoint': endpoint,
        },
      );
      final ctx = EmbedProviderContext(
        url: param.url,
        resolvedEndpoint: endpoint,
        width: param.width,
        locale: locale,
        brightness: brightness,
        facebookAppId: facebookAppId,
        facebookClientToken: facebookClientToken,
        rule: rule,
        strategy: rule.strategy,
        providerName: rule.providerName,
        variant: variant,
        capabilities: capabilities,
        proxyUrl: config?.proxyUrl,
        embedParams: param.embedParams,
        embedType: param.embedType,
      );

      final api = rule.apiFactory?.call(ctx) ?? rule.strategy.createApi(ctx);

      resolvedLogger.debug(
        'Using API handler',
        data: {
          'url': param.url,
          'api': api.runtimeType.toString(),
        },
      );
      return api;
    }

    // 4. Default fallback: Only if it's a likely oEmbed endpoint
    final isLikelyEndpoint =
        param.url.contains('/oembed') || param.url.contains('oembed.');

    if (isLikelyEndpoint) {
      resolvedLogger.debug(
        'Using generic oEmbed API for suspected endpoint',
        data: {'url': param.url},
      );
      return GenericEmbedApi(
        param.url,
        proxyUrl: config?.proxyUrl,
        width: param.width,
      );
    }

    // If discovery failed and it's not a likely endpoint, we shouldn't attempt
    // to use the content URL itself as an oEmbed endpoint.
    resolvedLogger.warning(
      'No oEmbed provider matched and URL does not look like an oEmbed endpoint',
      data: {'url': param.url},
    );
    throw EmbedProviderNotFoundException(url: param.url);
  }
}

/// Legacy static-access class for the embed service.
///
/// Prefer injecting [IEmbedService] or using [EmbedScope.serviceOf].
class EmbedService {
  /// The default global instance of [IEmbedService].
  static const IEmbedService instance = EmbedServiceImpl();

  /// Fetches OEmbed data using [EmbedConfig].
  static Future<EmbedData> getResult({
    required EmbedLoaderParam param,
    EmbedConfig? config,
    EmbedLogger? logger,
    EmbedCacheConfig? cacheConfig,
    http.Client? httpClient,
  }) =>
      instance.getResult(
        param: param,
        config: config,
        logger: logger,
        cacheConfig: cacheConfig,
        httpClient: httpClient,
      );

  /// Resolves the appropriate [BaseEmbedApi] for the given [param].
  static BaseEmbedApi getEmbedApiByEmbedType(
    EmbedLoaderParam param, {
    EmbedLogger? logger,
  }) =>
      instance.getEmbedApiByEmbedType(param, logger: logger);

  /// Resolves the cache request URI used for a given content [url].
  ///
  /// Returns `null` when no matching provider can be resolved.
  static Uri? resolveCacheUri(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    double? width,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
    EmbedLogger? logger,
  }) =>
      instance.resolveCacheUri(
        url,
        config: config,
        embedType: embedType,
        width: width,
        queryParameters: queryParameters,
        embedParams: embedParams,
        logger: logger,
      );

  /// Resolves how to render [url] given [config], returning a [EmbedRenderer]
  /// sealed type that callers can exhaustively pattern-match on.
  static EmbedRenderer resolveRender(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
  }) =>
      instance.resolveRender(
        url,
        config: config,
        embedType: embedType,
        logger: logger,
        queryParameters: queryParameters,
        embedParams: embedParams,
      );

  /// Resolves the [EmbedProviderRule] for a given [url] and [config].
  static EmbedProviderRule? resolveRule(
    String url, {
    EmbedConfig? config,
  }) =>
      instance.resolveRule(url, config: config);

  /// Resolves the iframe URL for a given content URL if iframe mode is active.
  /// Returns null if the provider doesn't support iframe mode or isn't enabled.
  static String? resolveIframeUrl(
    String url, {
    EmbedConfig? config,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    bool silent = false,
  }) =>
      instance.resolveIframeUrl(
        url,
        config: config,
        logger: logger,
        queryParameters: queryParameters,
        silent: silent,
      );
}
