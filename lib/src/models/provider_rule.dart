import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/provider_strategy.dart';
import 'package:flutter_embed/src/models/base_embed_params.dart';
import 'package:flutter_embed/src/services/api/base_embed_api.dart';

/// Internal cache for compiled [RegExp] objects to avoid redundant parsing.
final Map<String, RegExp> _oembedRegexCache = {};

/// Context passed to [EmbedProviderRule.apiFactory] when constructing an API client.
class EmbedProviderContext {
  final String url;
  final String resolvedEndpoint;
  final double width;
  final String locale;
  final Brightness brightness;
  final String facebookAppId;
  final String facebookClientToken;
  final String? proxyUrl;
  final BaseEmbedParams? embedParams;
  final EmbedProviderStrategy strategy;

  const EmbedProviderContext({
    required this.url,
    required this.resolvedEndpoint,
    required this.width,
    required this.locale,
    required this.brightness,
    required this.facebookAppId,
    required this.facebookClientToken,
    required this.strategy,
    this.proxyUrl,
    this.embedParams,
  });
}

/// A URL pattern sub-rule that maps to a specific API endpoint.
///
/// Used when a single provider (e.g. Facebook) has multiple URL shapes
/// that each go to different API endpoints.
class EmbedSubRule {
  final String pattern;
  final String endpoint;

  const EmbedSubRule({required this.pattern, required this.endpoint});

  /// Returns true if [url] matches this sub-rule's pattern.
  bool matches(String url) {
    final regex = _oembedRegexCache.putIfAbsent(
      pattern,
      () => RegExp(pattern, caseSensitive: false),
    );
    return regex.hasMatch(url);
  }
}

/// Describes how the library should discover and call the OEmbed API for a
/// specific provider.
class EmbedProviderRule {
  /// Regex pattern that matches URLs served by this provider.
  final String pattern;

  /// Default OEmbed API endpoint for this provider.
  final String endpoint;

  /// Human-readable provider name, e.g. `'YouTube'` or `'Vimeo'`.
  ///
  /// Used as the key for [EmbedProviderConfig.enabledProviders] and
  /// [EmbedProviderConfig.providerRenderModes].
  final String providerName;

  /// Optional sub-rules that override [endpoint] for specific URL shapes.
  final List<EmbedSubRule>? subRules;

  /// Whether this provider has been verified to work correctly.
  ///
  /// Unverified providers are excluded by default; set
  /// [EmbedProviderConfig.includeUnverified] to `true` to include them.
  final bool isVerified;

  /// Factory that constructs the [BaseEmbedApi] client for this provider.
  ///
  /// When `null`, falls back to [strategy.createApi].
  final BaseEmbedApi Function(EmbedProviderContext ctx)? apiFactory;

  /// Converts a content URL into an iframe `src` URL.
  ///
  /// When non-null and the provider's render mode is [EmbedRenderMode.iframe],
  /// the library loads this URL directly in a `WebView`, bypassing the OEmbed
  /// API entirely.
  final String? Function(String url)? iframeUrlBuilder;

  /// Returns `true` if the given in-WebView navigation URL should be allowed.
  ///
  /// Useful for providers that use internal redirects or plugin URLs. If this
  /// returns `false` or is `null`, default navigation handling applies
  /// (external links are opened in the host app).
  final bool Function(String url)? shouldAllowNavigation;

  /// Provider-specific behaviors for rendering and interaction.
  final EmbedProviderStrategy strategy;

  const EmbedProviderRule({
    required this.pattern,
    required this.endpoint,
    required this.providerName,
    this.strategy = const GenericEmbedProviderStrategy(),
    this.iframeUrlBuilder,
    this.shouldAllowNavigation,
    this.subRules,
    this.apiFactory,
    this.isVerified = false,
  });

  /// Resolves the actual API endpoint for a given [url], taking sub-rules into
  /// account. Falls back to [endpoint] when no sub-rule matches.
  String resolveEndpoint(String url) {
    if (subRules != null) {
      for (final subRule in subRules!) {
        if (subRule.matches(url)) {
          return subRule.endpoint;
        }
      }
    }
    return endpoint;
  }

  /// Returns `true` if [url] matches this rule's main pattern.
  bool matches(String url) {
    final regex = _oembedRegexCache.putIfAbsent(
      pattern,
      () => RegExp(pattern, caseSensitive: false),
    );
    return regex.hasMatch(url);
  }
}
