import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/core/embed_delegate.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_cache_config.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_loader_param.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/services/embed_service.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_data_loader.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
import 'package:flutter_embed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_embed/src/models/tiktok_embed_params.dart';

class EmbedWidgetLoader extends StatefulWidget {
  const EmbedWidgetLoader({
    super.key,
    required this.param,
    this.preloadedData,
    this.style,
    this.cacheConfig,
    this.scrollable = false,
    this.webViewBuilder,
  });

  final SocialEmbedParam param;
  final EmbedData? preloadedData;
  final EmbedStyle? style;
  final EmbedCacheConfig? cacheConfig;
  final bool scrollable;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  @override
  State<EmbedWidgetLoader> createState() => _EmbedWidgetLoaderState();
}

class _EmbedWidgetLoaderState extends State<EmbedWidgetLoader> {
  late EmbedController _controller;
  EmbedDelegate? _scopeDelegate;
  EmbedConfig? _scopeConfig;

  @override
  void initState() {
    super.initState();
    _scopeDelegate = EmbedScope.delegateOf(context, listen: false);
    _scopeConfig = EmbedScope.configOf(context, listen: false);
    _controller = _createController(
      delegate: _scopeDelegate,
      config: _scopeConfig,
    );
    _scheduleInitEmbedPost();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = EmbedScope.delegateOf(context);
    final config = EmbedScope.configOf(context);
    if (delegate != _scopeDelegate || config != _scopeConfig) {
      _scopeDelegate = delegate;
      _scopeConfig = config;
      _replaceController(delegate: delegate, config: config);
    }
  }

  @override
  void didUpdateWidget(covariant EmbedWidgetLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.param != widget.param ||
        oldWidget.preloadedData != widget.preloadedData) {
      _replaceController(delegate: _scopeDelegate, config: _scopeConfig);
      _scheduleInitEmbedPost();
    }
  }

  EmbedController _createController({
    required EmbedDelegate? delegate,
    required EmbedConfig? config,
  }) {
    return EmbedController(
      param: widget.param,
      delegate: delegate,
      config: config,
      preloadedData: widget.preloadedData,
    );
  }

  void _replaceController({
    required EmbedDelegate? delegate,
    required EmbedConfig? config,
  }) {
    final previous = _controller;
    _controller = _createController(delegate: delegate, config: config);
    previous.dispose();
  }

  void _scheduleInitEmbedPost() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.param.embedType != EmbedType.other) {
        EmbedScope.delegateOf(context)?.initEmbedPost(widget.param.url);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _controller.config ?? EmbedScope.configOf(context);
    final style = widget.style ?? config?.style;
    final logger = config?.logger;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showErrorWidget =
            _controller.loadingState == EmbedLoadingState.error &&
                _controller.didRetry;

        if (showErrorWidget) {
          final errorWidget = style?.errorBuilder?.call(context, null) ??
              EmbedScope.delegateOf(context)?.buildSocialEmbedErrorPlaceholder(
                context: context,
                param: widget.param,
              );
          return errorWidget ?? const Icon(Icons.error_outline);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
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

            if (widget.param.embedType == EmbedType.tiktok_v1) {
              return TikTokEmbedPlayer(
                videoIdOrUrl: widget.param.url,
                maxWidth: constraints.maxWidth,
                embedParams: widget.param.embedParams as TikTokEmbedParams?,
              );
            }

            final iframeUrl = EmbedService.resolveIframeUrl(
              widget.param.url,
              config: config,
              logger: logger,
              queryParameters: widget.param.queryParameters,
            );

            if (iframeUrl != null) {
              return EmbedWebView.url(
                param: widget.param,
                url: iframeUrl,
                maxWidth: constraints.maxWidth,
                controller: _controller,
                style: style,
                scrollable: widget.scrollable,
                webViewBuilder: widget.webViewBuilder,
              );
            }

            return EmbedDataLoader(
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
            );
          },
        );
      },
    );
  }
}
