import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/base_embed_params.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_surface.dart';
import 'package:flutter_oembed/src/widgets/embed_widget_loader.dart';

/// The primary widget for embedding social media content.
///
/// Provide a [url] and (optionally) an [embedType]. The library will auto-detect
/// the embed type when [embedType] is omitted.
///
/// Wrap your app (or a subtree) with [EmbedScope] to supply global
/// configuration.
///
/// ```dart
/// // Minimalist usage:
/// EmbedCard.url('https://twitter.com/x/status/123')
///
/// // Standard usage:
/// EmbedCard(url: 'https://twitter.com/x/status/123')
///
/// // With localized link tap handler:
/// EmbedCard.url(
///   'https://open.spotify.com/track/4cOdK2w...',
///   onLinkTap: (url, data) {
///     print('Clicked: $url');
///   },
/// )
/// ```
class EmbedCard extends StatelessWidget {
  final String url;
  final EmbedType? embedType;

  /// Optional callback when a link is tapped inside the embed or the footer.
  /// Overrides [EmbedConfig.onLinkTap] if provided.
  final void Function(String url, EmbedData? data)? onLinkTap;

  /// Pre-fetched OEmbed data. When provided, the card skips the API fetch
  /// and renders this data directly.
  final EmbedData? preloadedData;

  /// Per-widget visual customization. Overrides [EmbedConfig.style].
  final EmbedStyle? style;

  /// Per-widget cache configuration. Overrides [EmbedConfig.cache].
  final EmbedCacheConfig? cacheConfig;

  /// Whether the WebView should be scrollable internally.
  /// Overrides [EmbedConfig.scrollable].
  final bool? scrollable;

  /// Custom query parameters to pass to the OEmbed API (for supported providers).
  final Map<String, String>? queryParameters;
  final BaseEmbedParams? embedParams;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  const EmbedCard({
    super.key,
    required this.url,
    this.embedType,
    this.onLinkTap,
    this.preloadedData,
    this.style,
    this.cacheConfig,
    this.scrollable,
    this.queryParameters,
    this.embedParams,
    this.webViewBuilder,
  });

  /// A concise factory for creating an [EmbedCard] with a positional [url].
  ///
  /// This constructor is the preferred way to use the library when only the URL
  /// is known, as it emphasizes that the library will automatically detect
  /// the OEmbed provider.
  factory EmbedCard.url(
    String url, {
    Key? key,
    EmbedType? embedType,
    void Function(String url, EmbedData? data)? onLinkTap,
    EmbedData? preloadedData,
    EmbedStyle? style,
    EmbedCacheConfig? cacheConfig,
    bool? scrollable,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
    Widget Function(BuildContext context, Widget child)? webViewBuilder,
  }) {
    return EmbedCard(
      key: key,
      url: url,
      embedType: embedType,
      onLinkTap: onLinkTap,
      preloadedData: preloadedData,
      style: style,
      cacheConfig: cacheConfig,
      scrollable: scrollable,
      queryParameters: queryParameters,
      embedParams: embedParams,
      webViewBuilder: webViewBuilder,
    );
  }

  SocialEmbedParam _buildParam() {
    return SocialEmbedParam(
      url: url,
      embedType: embedType,
      key: key,
      queryParameters: queryParameters,
      embedParams: embedParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final param = _buildParam();
    final scopeConfig = EmbedScope.configOf(context);

    // Merge per-widget onLinkTap into the effective config so it reaches the
    // WebView's NavigationDelegate. Without this, onLinkTap was silently ignored.
    final effectiveConfig = onLinkTap != null
        ? (scopeConfig ?? const EmbedConfig()).copyWith(onLinkTap: onLinkTap)
        : scopeConfig;

    final style = this.style ?? effectiveConfig?.style;
    final scrollable = this.scrollable ?? effectiveConfig?.scrollable ?? false;

    return EmbedSurface(
      style: style,
      footerUrl: url,
      childBuilder: (context) {
        return EmbedWidgetLoader(
          param: param,
          preloadedData: preloadedData,
          config: effectiveConfig,
          style: style,
          cacheConfig: cacheConfig,
          scrollable: scrollable,
          webViewBuilder: webViewBuilder,
        );
      },
    );
  }
}
