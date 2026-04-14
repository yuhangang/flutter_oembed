import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_renderer.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/models/embed_webview_controls.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_data_loader.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';

class EmbedWidgetLoader extends StatefulWidget {
  const EmbedWidgetLoader({
    super.key,
    required this.param,
    this.preloadedData,
    this.controller,
    this.config,
    this.style,
    this.cacheConfig,
    this.embedConstraints,
    this.scrollable = false,
    this.webViewBuilder,
  });

  final SocialEmbedParam param;
  final EmbedData? preloadedData;
  final EmbedController? controller;

  /// Optional config override. If provided, takes precedence over [EmbedScope].
  /// Used by [EmbedCard] to merge per-widget callbacks (e.g. [onLinkTap]).
  final EmbedConfig? config;
  final EmbedStyle? style;
  final EmbedCacheConfig? cacheConfig;
  final EmbedConstraints? embedConstraints;
  final bool scrollable;
  final Widget Function(
    BuildContext context,
    EmbedWebViewControls controls,
    Widget child,
  )? webViewBuilder;

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
    if (!EmbedConfig.runtimeEqualsNullable(config, _scopeConfig)) {
      _scopeConfig = config;
      _replaceController(config: config);
    }
  }

  @override
  void didUpdateWidget(covariant EmbedWidgetLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextConfig = widget.config ?? EmbedScope.configOf(context);
    final configChanged =
        !EmbedConfig.runtimeEqualsNullable(oldWidget.config, widget.config) ||
            !EmbedConfig.runtimeEqualsNullable(_scopeConfig, nextConfig);

    if (oldWidget.param != widget.param ||
        oldWidget.preloadedData != widget.preloadedData ||
        oldWidget.controller != widget.controller ||
        configChanged) {
      _scopeConfig = nextConfig;
      _replaceController(config: _scopeConfig);
    }
  }

  EmbedController _createController({
    required EmbedConfig? config,
  }) {
    if (widget.controller != null) {
      widget.controller!.synchronize(
        param: widget.param,
        config: config,
        preloadedData: widget.preloadedData,
      );
      return widget.controller!;
    }
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
    if (!identical(previous, _controller) && widget.controller == null) {
      previous.dispose();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
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
                embedConstraints: widget.embedConstraints,
                scrollable: widget.scrollable,
                webViewBuilder: widget.webViewBuilder,
              );
            }

            final renderer = EmbedService.resolveRender(
              widget.param.url,
              config: config,
              embedType: widget.param.embedType,
              logger: logger,
              queryParameters: widget.param.queryParameters,
              embedParams: widget.param.embedParams,
            );

            return switch (renderer) {
              NativeWidgetRenderer(:final builder) => builder(
                  context,
                  constraints.maxWidth,
                  _controller,
                  widget.embedConstraints,
                ),
              IframeRenderer(:final iframeUrl) => EmbedWebView.url(
                  param: widget.param,
                  url: iframeUrl,
                  maxWidth: constraints.maxWidth,
                  controller: _controller,
                  style: style,
                  embedConstraints: widget.embedConstraints,
                  scrollable: widget.scrollable,
                  webViewBuilder: widget.webViewBuilder,
                ),
              OEmbedRenderer() => EmbedDataLoader(
                  param: widget.param,
                  controller: _controller,
                  config: config,
                  style: style,
                  cacheConfig: widget.cacheConfig,
                  embedConstraints: widget.embedConstraints,
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
