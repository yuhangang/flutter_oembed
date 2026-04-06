import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/models/base_embed_params.dart';
import 'package:flutter_embed/src/models/embed_cache_config.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/models/embed_tracking.dart';
import 'package:flutter_embed/src/widgets/embed_surface.dart';
import 'package:flutter_embed/src/widgets/embed_widget_loader.dart';

/// The primary widget for embedding social media content.
///
/// Provide a [url] and (optionally) an [embedType]. The library will auto-detect
/// the embed type when [embedType] is omitted.
///
/// Wrap your app (or a subtree) with [EmbedScope] to supply global
/// configuration and delegate builders.
///
/// ```dart
/// // Minimalist usage:
/// EmbedCard.url('https://twitter.com/x/status/123')
///
/// // Standard usage:
/// EmbedCard(url: 'https://twitter.com/x/status/123')
///
/// // With optional tracking info:
/// EmbedCard.url(
///   'https://open.spotify.com/track/4cOdK2w...',
///   tracking: EmbedTracking(
///     pageIdentifier: 'article_page',
///     source: 'editorial',
///     contentId: 'article_42',
///   ),
/// )
/// ```
class EmbedCard extends StatelessWidget {
  final String url;
  final EmbedType? embedType;

  /// Optional tracking, analytics, and instance identifiers.
  /// If omitted, identifiers are auto-generated from the URL.
  final EmbedTracking? tracking;

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
    this.tracking,
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
    EmbedTracking? tracking,
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
      tracking: tracking,
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
      tracking: tracking,
      queryParameters: queryParameters,
      embedParams: embedParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final param = _buildParam();
    final config = EmbedScope.configOf(context);
    final style = this.style ?? config?.style;
    final scrollable = this.scrollable ?? config?.scrollable ?? false;
    final delegate = EmbedScope.delegateOf(context);

    return EmbedSurface(
      style: style,
      footerUrl: url,
      fallbackWrapperBuilder: delegate != null
          ? (context, child) => delegate.buildSocialEmbedLinkWrapper(
                context: context,
                param: param,
                child: child,
              )
          : null,
      childBuilder: (context) {
        final shownEmbed = delegate?.showSocialEmbed(
                param.tracking.pageIdentifier!, param.url) ??
            true;

        if (!shownEmbed) {
          return delegate?.buildSocialEmbedLoadButton(
                context: context,
                param: param,
                identifier: param.tracking.pageIdentifier!,
              ) ??
              const SizedBox.shrink();
        }

        return EmbedWidgetLoader(
          param: param,
          preloadedData: preloadedData,
          style: style,
          cacheConfig: cacheConfig,
          scrollable: scrollable,
          webViewBuilder: webViewBuilder,
        );
      },
    );
  }
}
