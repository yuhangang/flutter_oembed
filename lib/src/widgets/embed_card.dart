import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/base_embed_params.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_surface.dart';
import 'package:flutter_oembed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_oembed/src/widgets/lazy_embed_node.dart';

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

  /// Overrides how the package derives and clamps the rendered embed height.
  final EmbedConstraints? embedConstraints;

  /// Deprecated shorthand for `embedConstraints.preferredHeight`.
  @Deprecated(
    'Use embedConstraints: EmbedConstraints(preferredHeight: ...) instead.',
  )
  final double? embedHeight;

  /// Whether the WebView should be scrollable internally.
  /// Overrides [EmbedConfig.scrollable].
  final bool? scrollable;

  /// Whether the widget should delay loading the WebView until it enters the viewport.
  /// Overrides [EmbedConfig.lazyLoad].
  final bool? lazyLoad;
  final EmbedController? controller;

  /// Custom query parameters to pass to the OEmbed API (for supported providers).
  final Map<String, String>? queryParameters;
  final BaseEmbedParams? embedParams;

  /// Optional identity used with [EmbedScope.reuseWebViews] to reuse a cached
  /// platform WebView when the same embed remounts later in the same scope.
  final Object? reuseKey;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  const EmbedCard({
    super.key,
    required this.url,
    this.embedType,
    this.onLinkTap,
    this.preloadedData,
    this.style,
    this.cacheConfig,
    this.embedConstraints,
    this.embedHeight,
    this.scrollable,
    this.lazyLoad,
    this.controller,
    this.queryParameters,
    this.embedParams,
    this.reuseKey,
    this.webViewBuilder,
  }) : assert(
          embedConstraints == null || embedHeight == null,
          'Use either embedConstraints or embedHeight, not both.',
        );

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
    EmbedConstraints? embedConstraints,
    double? embedHeight,
    bool? scrollable,
    bool? lazyLoad,
    EmbedController? controller,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
    Object? reuseKey,
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
      embedConstraints: embedConstraints,
      embedHeight: embedHeight,
      scrollable: scrollable,
      lazyLoad: lazyLoad,
      controller: controller,
      queryParameters: queryParameters,
      embedParams: embedParams,
      reuseKey: reuseKey,
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

  EmbedConstraints? get _effectiveEmbedConstraints =>
      embedConstraints ??
      (embedHeight != null
          ? EmbedConstraints(preferredHeight: embedHeight)
          : null);

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
    final lazyLoad = this.lazyLoad ?? effectiveConfig?.lazyLoad ?? false;

    Widget content = EmbedSurface(
      style: style,
      footerUrl: url,
      childBuilder: (context) {
        return EmbedWidgetLoader(
          param: param,
          preloadedData: preloadedData,
          controller: controller,
          config: effectiveConfig,
          style: style,
          cacheConfig: cacheConfig,
          embedConstraints: _effectiveEmbedConstraints,
          scrollable: scrollable,
          reuseKey: reuseKey,
          webViewBuilder: webViewBuilder,
        );
      },
    );

    if (lazyLoad) {
      content = LazyEmbedNode(
        url: url,
        style: style,
        embedConstraints: _effectiveEmbedConstraints,
        child: content,
      );
    }

    return content;
  }
}
