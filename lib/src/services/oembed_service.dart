import 'package:flutter/material.dart';
import 'package:oembed/src/services/oembed_apis.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/embed_loader_param.dart';
import 'package:oembed/src/models/oembed_config.dart';
import 'package:oembed/src/models/oembed_provider_config.dart';
import 'package:oembed/src/core/oembed_delegate.dart';
import 'package:oembed/src/logging/oembed_logger.dart';
import 'package:oembed/src/services/providers_snapshot.dart';
import 'package:oembed/src/services/api/reddit_embed_api.dart';
import 'package:collection/collection.dart';

/// Result of resolving how to render an embed.
sealed class OembedResolvedRender {}

/// The OEmbed API should be called to get the embed HTML.
final class OembedRenderData extends OembedResolvedRender {
  final BaseOembedApi api;
  OembedRenderData(this.api);
}

/// The embed should be loaded directly via an iframe URL.
final class OembedRenderIframe extends OembedResolvedRender {
  final String iframeUrl;
  OembedRenderIframe(this.iframeUrl);
}

class OembedService {
  /// Fetches OEmbed data using either [OembedConfig] or [OembedDelegate].
  static Future<OembedData> getResult({
    required EmbedLoaderParam param,
    OembedDelegate? delegate,
    OembedConfig? config,
    OembedLogger? logger,
  }) async {
    final resolvedLogger =
        logger ?? config?.logger ?? const OembedLogger.disabled();
    final cacheConfig = config?.cache;
    final locale = config?.locale ?? delegate?.getLocaleLanguageCode() ?? 'en';
    final brightness =
        config?.brightness ?? delegate?.getAppBrightness() ?? Brightness.light;

    resolvedLogger.debug(
      'Loading embed data for ${param.url} (${param.embedType.name})',
    );

    final api = _resolveApi(
      param,
      delegate: delegate,
      config: config,
      logger: resolvedLogger,
    );

    return api.getOembedData(
      param.url,
      locale: locale,
      brightness: brightness,
      cacheConfig: cacheConfig,
      logger: resolvedLogger,
    );
  }

  /// Resolves the appropriate [BaseOembedApi] for the given [param].
  static BaseOembedApi getOembedApiByEmbedType(
    EmbedLoaderParam param,
    OembedDelegate delegate, {
    OembedLogger? logger,
  }) {
    return _resolveApi(param, delegate: delegate, logger: logger);
  }

  static BaseOembedApi _resolveApi(
    EmbedLoaderParam param, {
    OembedDelegate? delegate,
    OembedConfig? config,
    OembedLogger? logger,
  }) {
    final resolvedLogger =
        logger ?? config?.logger ?? const OembedLogger.disabled();
    final facebookAppId =
        config?.facebookAppId ?? delegate?.facebookAppId ?? '';
    final facebookClientToken =
        config?.facebookClientToken ?? delegate?.facebookClientToken ?? '';
    final locale = config?.locale ?? delegate?.getLocaleLanguageCode() ?? 'en';
    final brightness =
        config?.brightness ?? delegate?.getAppBrightness() ?? Brightness.light;

    OembedProviderRule? rule;

    // 1. Check OembedProviderConfig rules first
    if (config != null) {
      rule = config.providers.effectiveProviders.firstWhereOrNull(
        (r) => r.matches(param.url),
      );
    } else {
      // Fallback for when no config is provided
      rule = kDefaultOembedProviders.firstWhereOrNull(
        (r) => r.matches(param.url),
      );
    }

    // 2. Static discovery check
    if (rule == null && config?.useDynamicDiscovery == true) {
      rule = _findRuleInSnapshot(param.url);
      if (rule != null) {
        resolvedLogger.debug(
          'Matched dynamically discovered provider "${rule.providerName}" for ${param.url}',
        );
      }
    }

    // 3. Resolve using found rule
    if (rule != null) {
      final endpoint = rule.resolveEndpoint(param.url);
      resolvedLogger.debug(
        'Matched provider "${rule.providerName}" for ${param.url} -> $endpoint',
      );
      final ctx = OembedProviderContext(
        url: param.url,
        resolvedEndpoint: endpoint,
        width: param.width,
        locale: locale,
        brightness: brightness,
        facebookAppId: facebookAppId,
        facebookClientToken: facebookClientToken,
        proxyUrl: config?.proxyUrl,
      );

      final api =
          rule.apiFactory?.call(ctx) ??
          GenericOembedApi(
            endpoint,
            proxyUrl: config?.proxyUrl,
            width: param.width,
          );
      resolvedLogger.debug('Using ${api.runtimeType} for ${param.url}');
      return api;
    }

    // 4. Legacy EmbedType dispatch as final fallback
    resolvedLogger.debug(
      'Falling back to embed type dispatch for ${param.url} (${param.embedType.name})',
    );
    switch (param.embedType) {
      case EmbedType.tiktok:
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
        );

      case EmbedType.x:
        return const XEmbedApi();

      case EmbedType.spotify:
        return const SpotifyEmbedApi();

      case EmbedType.youtube:
        return GenericOembedApi(
          'https://www.youtube.com/oembed',
          width: param.width,
        );

      case EmbedType.vimeo:
        return VimeoEmbedApi(param.width);

      case EmbedType.dailymotion:
        return GenericOembedApi(
          'https://www.dailymotion.com/services/oembed',
          width: param.width,
        );

      case EmbedType.soundcloud:
        return GenericOembedApi(
          'https://soundcloud.com/oembed',
          width: param.width,
        );
      case EmbedType.threads:
        return GenericOembedApi(
          'https://graph.threads.net/v1.0/oembed',
          width: param.width,
        );
      case EmbedType.reddit:
        return RedditEmbedApi(width: param.width);
      case EmbedType.other:
        throw Exception('Invalid embed type or provider not supported');
    }
  }

  /// Resolves the iframe URL for a given content URL if iframe mode is active.
  /// Returns null if the provider doesn't support iframe mode or isn't enabled.
  static String? resolveIframeUrl(
    String url, {
    OembedConfig? config,
    EmbedType? embedType,
    OembedLogger? logger,
  }) {
    if (config == null) return null;
    final resolvedLogger = logger ?? config.logger;

    final rule = config.resolvedProviders.effectiveProviders.firstWhereOrNull(
      (r) => r.matches(url),
    );
    if (rule == null) {
      resolvedLogger.debug('No iframe provider match for $url');
      return null;
    }

    final mode = config.resolvedProviders.getRenderMode(rule.providerName);
    if (mode != OembedRenderMode.iframe) {
      resolvedLogger.debug(
        'Provider "${rule.providerName}" is configured for $mode, not iframe',
      );
      return null;
    }

    final iframeUrl = rule.iframeUrlBuilder?.call(url);
    if (iframeUrl != null) {
      resolvedLogger.debug('Resolved iframe URL for $url -> $iframeUrl');
    }
    return iframeUrl;
  }

  /// Performs an O(1) domain-based lookup in the static snapshot.
  static OembedProviderRule? _findRuleInSnapshot(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final parts = host.split('.');

    // Check host and parent domains (e.g., 'www.youtube.com' -> 'youtube.com')
    for (int i = 0; i < parts.length - 1; i++) {
      final domain = parts.sublist(i).join('.');
      final rules = kOembedProvidersSnapshot[domain];
      if (rules != null) {
        final match = rules.firstWhereOrNull((r) => r.matches(url));
        if (match != null) return match;
      }
    }
    return null;
  }
}
