import 'package:flutter/material.dart';
import 'package:oembed/src/controllers/embed_controller.dart';
import 'package:oembed/src/core/oembed_scope.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbedWebView extends StatefulWidget {
  final SocialEmbedParam param;
  final OembedData? data;
  final String? url;
  final double maxWidth;
  final EmbedController controller;
  final bool scrollable;

  const EmbedWebView.data({
    super.key,
    required this.param,
    required OembedData this.data,
    required this.maxWidth,
    required this.controller,
    this.scrollable = false,
  }) : url = null;

  const EmbedWebView.url({
    super.key,
    required this.param,
    required String this.url,
    required this.maxWidth,
    required this.controller,
    this.scrollable = false,
  }) : data = null;

  @override
  State<EmbedWebView> createState() => _EmbedViewState();
}

class _EmbedViewState extends State<EmbedWebView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Resolve background color synchronously from context before the async gap.
      final bg = Theme.of(context).scaffoldBackgroundColor;
      await widget.controller.initEmbedWebview(
        backgroundColor: bg,
        embedData: widget.data,
        embedUrl: widget.url,
        maxWidth: widget.maxWidth,
        scrollable: widget.scrollable,
      );
    });
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    final config = OembedScope.configOf(context);
    return config?.style?.loadingBuilder?.call(context) ??
        OembedScope.of(context).buildSocialEmbedPlaceholder(
          context: context,
          embedType: widget.param.embedType,
        );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final config = widget.controller.config ?? OembedScope.configOf(context);
        final style = config?.style;
        final loadingState = widget.controller.loadingState;
        final double? aspectRatio =
            widget.data?.aspectRatio ??
            widget.controller.preloadedData?.aspectRatio;

        double height =
            (aspectRatio != null
                ? widget.maxWidth / aspectRatio
                : (widget.controller.height ?? widget.maxWidth));

        if (widget.scrollable && style != null) {
          height = height.clamp(0.0, style.maxScrollableHeight);
        }

        return VisibilityDetector(
          key: ValueKey(widget.param),
          onVisibilityChanged:
              (info) => widget.controller.updateVisibility(
                info.visibleFraction > 0,
                onVisibilityChange: (visible) {
                  if (!visible &&
                      widget.param.embedType == EmbedType.tiktok &&
                      loadingState == EmbedLoadingState.loaded) {
                    widget.controller.pauseMedias();
                  }
                },
              ),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: widget.controller.webViewController),
                if (loadingState == EmbedLoadingState.loading)
                  _buildLoadingOverlay(context)
                else if (loadingState == EmbedLoadingState.error ||
                    loadingState == EmbedLoadingState.noConnection)
                  GestureDetector(
                    onTap: () {
                      final hasConnection =
                          OembedScope.of(context).checkConnection();
                      if (hasConnection) {
                        widget.controller.setLoadingState(
                          EmbedLoadingState.loading,
                        );
                        if (loadingState == EmbedLoadingState.error) {
                          widget.controller.setDidRetry();
                          widget.controller.refresh();
                        } else {
                          widget.controller.webViewController.reload();
                        }
                      }
                    },
                    child:
                        style?.errorBuilder?.call(context, null) ??
                        OembedScope.of(context)
                            .buildSocialEmbedRefreshPlaceholder(
                              context: context,
                              param: widget.param,
                              onTap: () {}, // Already handled by GestureDetector
                            ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
