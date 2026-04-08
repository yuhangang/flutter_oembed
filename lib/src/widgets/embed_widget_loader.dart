import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_data_loader.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_oembed/src/models/tiktok_embed_params.dart';

class EmbedWidgetLoader extends StatefulWidget {
  const EmbedWidgetLoader({
    super.key,
    required this.param,
    this.preloadedData,
    this.config,
    this.style,
    this.cacheConfig,
    this.scrollable = false,
    this.webViewBuilder,
  });

  final SocialEmbedParam param;
  final EmbedData? preloadedData;

  /// Optional config override. If provided, takes precedence over [EmbedScope].
  /// Used by [EmbedCard] to merge per-widget callbacks (e.g. [onLinkTap]).
  final EmbedConfig? config;
  final EmbedStyle? style;
  final EmbedCacheConfig? cacheConfig;
  final bool scrollable;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  @override
  State<EmbedWidgetLoader> createState() => _EmbedWidgetLoaderState();
}

class _EmbedWidgetLoaderState extends State<EmbedWidgetLoader> {
  late EmbedController _controller;
  EmbedConfig? _scopeConfig;

  @override
  void initState() {
    super.initState();
    // Prefer the explicit config override; fall back to EmbedScope.
    _scopeConfig = widget.config ?? EmbedScope.configOf(context, listen: false);
    _controller = _createController(
      config: _scopeConfig,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // widget.config takes full precedence; only react to scope changes when
    // no explicit config is provided.
    if (widget.config != null) return;
    final config = EmbedScope.configOf(context);
    if (config != _scopeConfig) {
      _scopeConfig = config;
      _replaceController(config: config);
    }
  }

  @override
  void didUpdateWidget(covariant EmbedWidgetLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.param != widget.param ||
        oldWidget.preloadedData != widget.preloadedData ||
        !identical(oldWidget.config, widget.config)) {
      _scopeConfig = widget.config ?? EmbedScope.configOf(context);
      _replaceController(config: _scopeConfig);
    }
  }

  EmbedController _createController({
    required EmbedConfig? config,
  }) {
    return EmbedController(
      param: widget.param,
      config: config,
      preloadedData: widget.preloadedData,
    );
  }

  void _replaceController({
    required EmbedConfig? config,
  }) {
    final previous = _controller;
    _controller = _createController(config: config);
    previous.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prefer explicit config override, then controller config, then scope.
    final config =
        widget.config ?? _controller.config ?? EmbedScope.configOf(context);
    final style = widget.style ?? config?.style;
    final logger = config?.logger;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showErrorWidget =
            _controller.loadingState == EmbedLoadingState.error &&
                _controller.didRetry;

        if (showErrorWidget) {
          final errorWidget =
              style?.errorBuilder?.call(context, _controller.lastError);
          return errorWidget ?? const Icon(Icons.error_outline);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Short-circuit for pre-fetched data (avoids a resolveRender call).
            if (widget.preloadedData != null) {
              return EmbedWebView.data(
                param: widget.param,
                data: widget.preloadedData!,
                maxWidth: constraints.maxWidth,
                controller: _controller,
                style: style,
                scrollable: widget.scrollable,
                webViewBuilder: widget.webViewBuilder,
              );
            }

            final render = EmbedService.resolveRender(
              widget.param.url,
              config: config,
              embedType: widget.param.embedType,
              logger: logger,
              queryParameters: widget.param.queryParameters,
            );

            return switch (render) {
              EmbedRenderNativePlayer() => TikTokEmbedPlayer(
                  videoIdOrUrl: widget.param.url,
                  maxWidth: constraints.maxWidth,
                  embedParams: widget.param.embedParams as TikTokEmbedParams?,
                ),
              EmbedRenderIframe(:final iframeUrl) => EmbedWebView.url(
                  param: widget.param,
                  url: iframeUrl,
                  maxWidth: constraints.maxWidth,
                  controller: _controller,
                  style: style,
                  scrollable: widget.scrollable,
                  webViewBuilder: widget.webViewBuilder,
                ),
              EmbedRenderOEmbed() || EmbedRenderPreloaded() => EmbedDataLoader(
                  param: widget.param,
                  controller: _controller,
                  config: config,
                  style: style,
                  cacheConfig: widget.cacheConfig,
                  scrollable: widget.scrollable,
                  webViewBuilder: widget.webViewBuilder,
                  loaderParam: EmbedLoaderParam(
                    url: widget.param.url,
                    embedType: widget.param.embedType,
                    width: constraints.maxWidth,
                    queryParameters: widget.param.queryParameters,
                    embedParams: widget.param.embedParams,
                  ),
                ),
            };
          },
        );
      },
    );
  }
}
