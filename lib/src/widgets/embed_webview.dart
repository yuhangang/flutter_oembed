import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/controllers/embed_webview_driver.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbedWebView extends StatefulWidget {
  final SocialEmbedParam param;
  final EmbedData? data;
  final String? url;
  final double maxWidth;
  final EmbedController controller;
  final EmbedStyle? style;
  final bool scrollable;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  const EmbedWebView.data({
    super.key,
    required this.param,
    required EmbedData this.data,
    required this.maxWidth,
    required this.controller,
    this.style,
    this.scrollable = false,
    this.webViewBuilder,
  }) : url = null;

  const EmbedWebView.url({
    super.key,
    required this.param,
    required String this.url,
    required this.maxWidth,
    required this.controller,
    this.style,
    this.scrollable = false,
    this.webViewBuilder,
  }) : data = null;

  @override
  State<EmbedWebView> createState() => _EmbedViewState();
}

class _EmbedViewState extends State<EmbedWebView> {
  late EmbedWebViewDriver _driver;

  @override
  void initState() {
    super.initState();
    _driver = EmbedWebViewDriver(controller: widget.controller);
    _scheduleInit();
  }

  @override
  void didUpdateWidget(covariant EmbedWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged) {
      _driver.dispose();
      _driver = EmbedWebViewDriver(controller: widget.controller);
    }

    if (controllerChanged ||
        oldWidget.data != widget.data ||
        oldWidget.url != widget.url ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.scrollable != widget.scrollable ||
        oldWidget.param != widget.param) {
      _scheduleInit(forceReload: true);
    }
  }

  void _scheduleInit({bool forceReload = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final bg = Theme.of(context).scaffoldBackgroundColor;
      await _driver.initEmbedWebview(
        backgroundColor: bg,
        embedData: widget.data,
        embedUrl: widget.url,
        maxWidth: widget.maxWidth,
        scrollable: widget.scrollable,
        forceReload: forceReload,
      );
    });
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  Widget _buildLoadingOverlay(BuildContext context, EmbedStyle? style) {
    return style?.loadingBuilder?.call(context) ??
        const Center(child: CircularProgressIndicator());
  }

  Widget _buildWebView(BuildContext context, EmbedStyle? style) {
    return WebViewWidget(controller: _driver.webViewController);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final config = widget.controller.config ?? EmbedScope.configOf(context);
        final style = widget.style ?? config?.style;
        final loadingState = widget.controller.loadingState;
        final double? aspectRatio = widget.data?.aspectRatio ??
            widget.controller.preloadedData?.aspectRatio;

        double height = (aspectRatio != null
            ? widget.maxWidth / aspectRatio
            : (widget.controller.height ?? widget.maxWidth));

        if (widget.scrollable && style != null) {
          height = height.clamp(0.0, style.maxScrollableHeight);
        }

        final effectiveWebViewBuilder =
            widget.webViewBuilder ?? style?.webViewBuilder;

        Widget webViewContainer = SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildWebView(context, style),
              if (loadingState == EmbedLoadingState.loading)
                _buildLoadingOverlay(context, style)
              else if (loadingState == EmbedLoadingState.error ||
                  loadingState == EmbedLoadingState.noConnection)
                GestureDetector(
                  onTap: () {
                    widget.controller.setLoadingState(
                      EmbedLoadingState.loading,
                    );
                    if (loadingState == EmbedLoadingState.error) {
                      widget.controller.setDidRetry();
                      _driver.refresh();
                    } else {
                      _driver.webViewController.reload();
                    }
                  },
                  child: style?.errorBuilder?.call(context, null) ??
                      const Icon(Icons.refresh),
                ),
            ],
          ),
        );

        if (effectiveWebViewBuilder != null) {
          webViewContainer = effectiveWebViewBuilder(context, webViewContainer);
        }

        return VisibilityDetector(
          key: ValueKey(widget.param),
          onVisibilityChanged: (info) => widget.controller.updateVisibility(
            info.visibleFraction > 0,
            onVisibilityChange: (visible) {
              if (!visible && loadingState == EmbedLoadingState.loaded) {
                _driver.pauseMedias();
              }
            },
          ),
          child: webViewContainer,
        );
      },
    );
  }
}
