import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/base_embed_params.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/provider_rule.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/services/provider_registry.dart';
import 'package:flutter_oembed/src/services/providers_snapshot.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

/// Result of resolving how to render an embed.
sealed class EmbedResolvedRender {
  const EmbedResolvedRender();
}

/// The OEmbed API should be called to fetch the embed HTML.
final class EmbedRenderOEmbed extends EmbedResolvedRender {
  const EmbedRenderOEmbed();
}

/// The embed should be loaded directly via an iframe URL.
final class EmbedRenderIframe extends EmbedResolvedRender {
  final String iframeUrl;
  const EmbedRenderIframe(this.iframeUrl);
}

/// Pre-fetched [EmbedData] is already available — skip the API call.
final class EmbedRenderPreloaded extends EmbedResolvedRender {
  const EmbedRenderPreloaded();
}

/// Use the provider's native player widget (e.g. TikTok v1).
final class EmbedRenderNativePlayer extends EmbedResolvedRender {
  const EmbedRenderNativePlayer();
}

class EmbedService {
  /// Fetches OEmbed data using [EmbedConfig].
  static Future<EmbedData> getResult({
    required EmbedLoaderParam param,
    EmbedConfig? config,
    EmbedLogger? logger,
    EmbedCacheConfig? cacheConfig,
    http.Client? httpClient,
  }) async {
    final resolvedLogger =
        logger ?? config?.logger ?? const EmbedLogger.disabled();
    final resolvedCacheConfig = cacheConfig ?? config?.cache;
    final locale = config?.locale ?? 'en';
    final brightness = config?.brightness ?? Brightness.light;

    resolvedLogger.debug(
      'Loading embed data',
      data: {
        'url': param.url,
        'embedType': param.embedType.name,
      },
    );

    final api = _resolveApi(
      param,
      config: config,
      logger: resolvedLogger,
    );

    return api.getEmbedData(
      param.url,
      locale: locale,
      brightness: brightness,
      cacheConfig: resolvedCacheConfig,
      logger: resolvedLogger,
      queryParameters: param.queryParameters,
      httpClient: httpClient,
    );
  }

  /// Resolves the appropriate [BaseEmbedApi] for the given [param].
  static BaseEmbedApi getEmbedApiByEmbedType(
    EmbedLoaderParam param, {
    EmbedLogger? logger,
  }) {
    return _resolveApi(param, logger: logger);
  }

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
  }) {
    try {
      final param = EmbedLoaderParam(
        url: url,
        embedType: embedType ?? EmbedType.other,
        width: width ?? 0,
        queryParameters: queryParameters,
        embedParams: embedParams,
      );
      final api = _resolveApi(param, config: config, logger: logger);
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

  /// Resolves how to render [url] given [config], returning a [EmbedResolvedRender]
  /// sealed type that callers can exhaustively pattern-match on.
  ///
  /// Order of precedence:
  /// 1. Preloaded data (caller responsibility — widget checks widget.preloadedData)
  /// 2. Native player (e.g. TikTok v1)
  /// 3. Iframe mode (config overrides provider render mode)
  /// 4. OEmbed API fetch
  static EmbedResolvedRender resolveRender(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
  }) {
    // Native player (e.g. EmbedType.tiktok_v1)
    if (embedType == EmbedType.tiktok_v1) {
      return const EmbedRenderNativePlayer();
    }

    // Iframe mode
    final iframeUrl = resolveIframeUrl(
      url,
      config: config,
      embedType: embedType,
      logger: logger,
      queryParameters: queryParameters,
    );
    if (iframeUrl != null) {
      return EmbedRenderIframe(iframeUrl);
    }

    // Default: OEmbed API fetch
    return const EmbedRenderOEmbed();
  }

  /// Resolves the [EmbedProviderRule] for a given [url] and [config].
  static EmbedProviderRule? resolveRule(
    String url, {
    EmbedConfig? config,
  }) {
    EmbedProviderRule? rule;

    // 1. Check EmbedProviderConfig rules first
    if (config != null) {
      rule = config.resolvedProviders.effectiveProviders.firstWhereOrNull(
        (r) => r.matches(url),
      );
    } else {
      // Fallback for when no config is provided
      rule = kDefaultEmbedProviders.firstWhereOrNull(
        (r) => r.matches(url),
      );
    }

    // 2. Static discovery check
    if (rule == null &&
        (config?.useDynamicDiscovery == true ||
            config?.providers.useDynamicDiscovery == true)) {
      rule = _findRuleInSnapshot(url);
    }

    return rule;
  }

  static BaseEmbedApi _resolveApi(
    EmbedLoaderParam param, {
    EmbedConfig? config,
    EmbedLogger? logger,
  }) {
    final resolvedLogger =
        logger ?? config?.logger ?? const EmbedLogger.disabled();
    final facebookAppId = config?.facebookAppId ?? '';
    final facebookClientToken = config?.facebookClientToken ?? '';
    final locale = config?.locale ?? 'en';
    final brightness = config?.brightness ?? Brightness.light;

    final rule = resolveRule(param.url, config: config);

    // 3. Resolve using found rule
    if (rule != null) {
      final endpoint = rule.resolveEndpoint(param.url);
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
        strategy: rule.strategy,
        proxyUrl: config?.proxyUrl,
        embedParams: param.embedParams,
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

  /// Resolves the iframe URL for a given content URL if iframe mode is active.
  /// Returns null if the provider doesn't support iframe mode or isn't enabled.
  static String? resolveIframeUrl(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
  }) {
    if (config == null) return null;
    final resolvedLogger = logger ?? config.logger;

    final rule = resolveRule(url, config: config);
    if (rule == null) {
      resolvedLogger.debug('No iframe provider match', data: {'url': url});
      return null;
    }

    final mode = config.resolvedProviders.getRenderMode(rule.providerName);
    if (mode != EmbedRenderMode.iframe) {
      resolvedLogger.debug(
        'Rendering mode mismatch',
        data: {
          'url': url,
          'provider': rule.providerName,
          'configuredMode': mode.name,
          'requiredMode': 'iframe',
        },
      );
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

  /// Performs an O(1) domain-based lookup in the static snapshot.
  static EmbedProviderRule? _findRuleInSnapshot(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final parts = host.split('.');

    // Check host and parent domains (e.g., 'www.youtube.com' -> 'youtube.com')
    for (int i = 0; i < parts.length - 1; i++) {
      final domain = parts.sublist(i).join('.');

      // Try exact match (e.g. 'ted.com')
      var rules = kEmbedProvidersSnapshot[domain];
      rules ??= kEmbedProvidersSnapshot['*.$domain'];

      if (rules != null && rules.isNotEmpty) {
        final match = rules.firstWhereOrNull((r) => r.matches(url));
        if (match != null) return match;
      }
    }
    return null;
  }
}
