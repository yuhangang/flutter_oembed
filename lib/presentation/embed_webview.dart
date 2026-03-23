import 'package:oembed/application/embed_controller.dart';
import 'package:oembed/data/oembed_data.dart';
import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:oembed/domain/entities/social_embed_param.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:oembed/oembed_scope.dart';

class EmbedWebView extends StatefulWidget {
  final SocialEmbedParam param;
  final OembedData? data;
  final String? url;
  final double maxWidth;
  final EmbedController controller;

  const EmbedWebView.data({
    super.key,
    required this.param,
    required OembedData this.data,
    required this.maxWidth,
    required this.controller,
  }) : url = null;

  const EmbedWebView.url({
    super.key,
    required this.param,
    required String this.url,
    required this.maxWidth,
    required this.controller,
  }) : data = null;

  @override
  State<EmbedWebView> createState() => _EmbedViewState();
}

class _EmbedViewState extends State<EmbedWebView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await widget.controller.initEmbedWebview(
        context,
        embedData: widget.data,
        embedUrl: widget.url,
        maxWidth: widget.maxWidth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final loadingState = widget.controller.loadingState;
        final height = (widget.param.embedType == EmbedType.tiktok)
             ? widget.maxWidth * 16 / 9
             : (widget.controller.height ?? widget.maxWidth);

        return VisibilityDetector(
          key: ValueKey(widget.param),
          onVisibilityChanged: (info) => widget.controller.updateVisibility(
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
                  OembedScope.of(context).buildSocialEmbedPlaceholder(context: context, embedType: widget.param.embedType)
                else if (loadingState == EmbedLoadingState.error)
                  OembedScope.of(context).buildSocialEmbedRefreshPlaceholder(
                    context: context, 
                    param: widget.param, 
                    onTap: () {
                      final hasConnection = OembedScope.of(context).checkConnection();

                      if (hasConnection) {
                        widget.controller.setLoadingState(EmbedLoadingState.loading);
                        widget.controller.setDidRetry();
                        widget.controller.refresh();
                      }
                    },
                  )
                else if (loadingState == EmbedLoadingState.noConnection)
                  OembedScope.of(context).buildSocialEmbedRefreshPlaceholder(
                    context: context, 
                    param: widget.param, 
                    onTap: () {
                      widget.controller.setLoadingState(EmbedLoadingState.loading);
                      widget.controller.webViewController.reload();
                    }
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
