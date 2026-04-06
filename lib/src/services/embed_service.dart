import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_delegate.dart';
import 'package:flutter_embed/src/logging/embed_logger.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_cache_config.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_loader_param.dart';
import 'package:flutter_embed/src/models/embed_provider_config.dart';
import 'package:flutter_embed/src/models/meta_embed_params.dart';
import 'package:flutter_embed/src/models/soundcloud_embed_params.dart';
import 'package:flutter_embed/src/models/vimeo_embed_params.dart';
import 'package:flutter_embed/src/models/x_embed_params.dart';
import 'package:flutter_embed/src/services/embed_apis.dart';
import 'package:flutter_embed/src/services/providers_snapshot.dart';

/// Result of resolving how to render an embed.
sealed class EmbedResolvedRender {}

/// The OEmbed API should be called to get the embed HTML.
final class EmbedRenderData extends EmbedResolvedRender {
  final BaseEmbedApi api;
  EmbedRenderData(this.api);
}

/// The embed should be loaded directly via an iframe URL.
final class EmbedRenderIframe extends EmbedResolvedRender {
  final String iframeUrl;
  EmbedRenderIframe(this.iframeUrl);
}

class EmbedService {
  /// Fetches OEmbed data using either [EmbedConfig] or [EmbedDelegate].
  static Future<EmbedData> getResult({
    required EmbedLoaderParam param,
    EmbedDelegate? delegate,
    EmbedConfig? config,
    EmbedLogger? logger,
    EmbedCacheConfig? cacheConfig,
  }) async {
    final resolvedLogger =
        logger ?? config?.logger ?? const EmbedLogger.disabled();
    final resolvedCacheConfig = cacheConfig ?? config?.cache;
    final locale = config?.locale ?? delegate?.getLocaleLanguageCode() ?? 'en';
    final brightness =
        config?.brightness ?? delegate?.getAppBrightness() ?? Brightness.light;

    resolvedLogger.debug(
      'Loading embed data',
      data: {
        'url': param.url,
        'embedType': param.embedType.name,
      },
    );

    final api = _resolveApi(
      param,
      delegate: delegate,
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
    );
  }

  /// Resolves the appropriate [BaseEmbedApi] for the given [param].
  static BaseEmbedApi getEmbedApiByEmbedType(
    EmbedLoaderParam param,
    EmbedDelegate delegate, {
    EmbedLogger? logger,
  }) {
    return _resolveApi(param, delegate: delegate, logger: logger);
  }

  static BaseEmbedApi _resolveApi(
    EmbedLoaderParam param, {
    EmbedDelegate? delegate,
    EmbedConfig? config,
    EmbedLogger? logger,
  }) {
    final resolvedLogger =
        logger ?? config?.logger ?? const EmbedLogger.disabled();
    final facebookAppId =
        config?.facebookAppId ?? delegate?.facebookAppId ?? '';
    final facebookClientToken =
        config?.facebookClientToken ?? delegate?.facebookClientToken ?? '';
    final locale = config?.locale ?? delegate?.getLocaleLanguageCode() ?? 'en';
    final brightness =
        config?.brightness ?? delegate?.getAppBrightness() ?? Brightness.light;

    EmbedProviderRule? rule;

    // 1. Check EmbedProviderConfig rules first
    if (config != null) {
      rule = config.providers.effectiveProviders.firstWhereOrNull(
        (r) => r.matches(param.url),
      );
    } else {
      // Fallback for when no config is provided
      rule = kDefaultEmbedProviders.firstWhereOrNull(
        (r) => r.matches(param.url),
      );
    }

    // 2. Static discovery check
    if (rule == null && config?.useDynamicDiscovery == true) {
      rule = _findRuleInSnapshot(param.url);
      if (rule != null) {
        resolvedLogger.debug(
          'Matched dynamically discovered provider',
          data: {
            'url': param.url,
            'provider': rule.providerName,
          },
        );
      }
    }

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
        proxyUrl: config?.proxyUrl,
        embedParams: param.embedParams,
      );

      final api = rule.apiFactory?.call(ctx) ??
          GenericEmbedApi(
            endpoint,
            proxyUrl: config?.proxyUrl,
            width: param.width,
          );
      resolvedLogger.debug(
        'Using API handler',
        data: {
          'url': param.url,
          'api': api.runtimeType.toString(),
        },
      );
      return api;
    }

    // 4. Legacy EmbedType dispatch as final fallback
    resolvedLogger.debug(
      'Falling back to embed type dispatch',
      data: {
        'url': param.url,
        'embedType': param.embedType.name,
      },
    );
    switch (param.embedType) {
      case EmbedType.tiktok:
      case EmbedType.tiktok_v1:
        return const TikTokEmbedApi();

      case EmbedType.facebook_video:
      case EmbedType.facebook_post:
      case EmbedType.facebook:
      case EmbedType.instagram:
        return MetaEmbedApi(
          param.embedType,
          param.width,
          facebookAppId,
          facebookClientToken,
          proxyUrl: config?.proxyUrl,
          metaParams: param.embedParams as MetaEmbedParams?,
        );

      case EmbedType.x:
        return XEmbedApi(xParams: param.embedParams as XEmbedParams?);

      case EmbedType.spotify:
        return const SpotifyEmbedApi();

      case EmbedType.youtube:
        return GenericEmbedApi(
          'https://www.youtube.com/oembed',
          width: param.width,
        );

      case EmbedType.vimeo:
        return VimeoEmbedApi(
          param.width,
          vimeoParams: param.embedParams as VimeoEmbedParams?,
        );

      case EmbedType.dailymotion:
        return GenericEmbedApi(
          'https://www.dailymotion.com/services/oembed',
          width: param.width,
        );
      case EmbedType.soundcloud:
        return SoundCloudEmbedApi(
          param.width,
          soundCloudParams: param.embedParams as SoundCloudEmbedParams?,
        );
      case EmbedType.threads:
        return MetaEmbedApi(
          param.embedType,
          param.width,
          facebookAppId,
          facebookClientToken,
          proxyUrl: config?.proxyUrl,
          metaParams: param.embedParams as MetaEmbedParams?,
        );
      case EmbedType.reddit:
        return RedditEmbedApi(width: param.width);
      case EmbedType.giphy:
        return GenericEmbedApi(
          'https://giphy.com/services/oembed',
          width: param.width,
        );
      case EmbedType.other:
        throw Exception('Invalid embed type or provider not supported');
    }
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

    final rule = config.resolvedProviders.effectiveProviders.firstWhereOrNull(
      (r) => r.matches(url),
    );
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
      final rules = kEmbedProvidersSnapshot[domain];
      if (rules != null) {
        final match = rules.firstWhereOrNull((r) => r.matches(url));
        if (match != null) return match;
      }
    }
    return null;
  }
}
