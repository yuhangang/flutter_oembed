import 'package:flutter/material.dart';
import 'package:oembed/src/controllers/embed_controller.dart';
import 'package:oembed/src/core/oembed_scope.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/oembed_cache_config.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:oembed/src/models/oembed_style.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:oembed/src/widgets/embed_surface.dart';
import 'package:oembed/src/widgets/embed_widget_loader.dart';
import 'package:oembed/src/utils/embed_matchers.dart';
import 'package:oembed/src/utils/embed_link_utils.dart';

/// The primary widget for embedding social media content.
///
/// Provide a [url] and (optionally) an [embedType]. The library will auto-detect
/// the embed type when [embedType] is omitted.
///
/// Wrap your app (or a subtree) with [OembedScope] to supply global
/// configuration and delegate builders.
///
/// ```dart
/// // Minimal usage — all metadata params have sensible auto-defaults:
/// EmbedCard(url: 'https://twitter.com/x/status/123')
///
/// // With optional tracking info:
/// EmbedCard(
///   url: 'https://open.spotify.com/track/4cOdK2w...',
///   pageIdentifier: 'article_page',
///   source: 'editorial',
///   contentId: 'article_42',
/// )
/// ```
class EmbedCard extends StatefulWidget {
  final String url;
  final EmbedType? embedType;

  /// Identifier for the page/screen this embed appears on.
  /// Used for analytics and gating. Defaults to a hash of the URL.
  final String pageIdentifier;

  /// Source string passed to link-click callbacks. Defaults to `'embed'`.
  final String source;

  /// Content ID for the host-app entity that contains this embed.
  /// Defaults to a hash-based ID.
  final String contentId;

  /// Optional DOM element identifier when multiple embeds of the same URL
  /// appear on the same page. Defaults to null.
  final String? elementId;

  /// Secondary identifier used to force widget disposal/re-creation when the
  /// parent changes. Defaults to an empty string.
  final String extraIdentifier;

  /// Provide an already-constructed [EmbedController] (advanced use).
  final EmbedController? controller;

  /// Pre-fetched OEmbed data. When provided, the card skips the API fetch
  /// and renders this data directly.
  final OembedData? preloadedData;

  /// Per-widget visual customization. Overrides [OembedConfig.style].
  final OembedStyle? style;

  /// Per-widget cache configuration. Overrides [OembedConfig.cache].
  final OembedCacheConfig? cacheConfig;

  /// Whether the WebView should be scrollable internally.
  /// Overrides [OembedConfig.scrollable].
  final bool? scrollable;

  const EmbedCard({
    super.key,
    required this.url,
    this.embedType,
    this.pageIdentifier = '',
    this.source = 'embed',
    this.contentId = '',
    this.elementId,
    this.extraIdentifier = '',
    this.controller,
    this.preloadedData,
    this.style,
    this.cacheConfig,
    this.scrollable,
  });

  @override
  State<EmbedCard> createState() => _EmbedCardState();
}

class _EmbedCardState extends State<EmbedCard> {
  late final SocialEmbedParam param = () {
    final type = widget.embedType ?? EmbedMatchers.getEmbedType(widget.url);
    final url =
        type == EmbedType.youtube ? getYoutubeEmbedParam(widget.url) : widget.url;

    return SocialEmbedParam(
      url: url,
      embedType: type,
      source: widget.source,
      contentId: widget.contentId.isEmpty
          ? 'embed_${widget.url.hashCode.abs()}'
          : widget.contentId,
      pageIdentifier: widget.pageIdentifier.isEmpty
          ? 'page_${widget.url.hashCode.abs()}'
          : widget.pageIdentifier,
      elementId: widget.elementId,
      extraIdentifier: widget.extraIdentifier,
    );
  }();

  EmbedController? _internalController;
  EmbedController get _controller => widget.controller ?? _internalController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller == null && _internalController == null) {
      final config =
          widget.cacheConfig != null
              ? OembedScope.configOf(context)?.copyWith(cache: widget.cacheConfig)
              : OembedScope.configOf(context);

      _internalController = EmbedController(
        param: param,
        delegate: OembedScope.delegateOf(context),
        config: config,
        preloadedData: widget.preloadedData,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.embedType != EmbedType.other) {
        OembedScope.delegateOf(context)?.initEmbedPost(param.url);
      }
    });
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = OembedScope.configOf(context);
    final style = widget.style ?? config?.style;
    final scrollable = widget.scrollable ?? config?.scrollable ?? false;
    final delegate = OembedScope.delegateOf(context);

    return EmbedSurface(
      style: style,
      footerUrl: widget.url,
      fallbackWrapperBuilder:
          delegate != null
              ? (context, child) => delegate.buildSocialEmbedLinkWrapper(
                context: context,
                param: param,
                child: child,
              )
              : null,
      childBuilder: (context) {
        // Phase 5: EmbedWidgetLoader is the single decision point for render mode.
        // Previously, EmbedCard also checked for iframe URLs — that logic now lives
        // exclusively in EmbedWidgetLoader, eliminating duplication.
        final shownEmbed =
            delegate?.showSocialEmbed(widget.pageIdentifier, param.url) ?? true;

        if (!shownEmbed) {
          return delegate?.buildSocialEmbedLoadButton(
                context: context,
                param: param,
                identifier: widget.pageIdentifier,
              ) ??
              const SizedBox.shrink();
        }

        return EmbedWidgetLoader(
          param: param,
          controller: _controller,
          style: style,
          scrollable: scrollable,
        );
      },
    );
  }
}
