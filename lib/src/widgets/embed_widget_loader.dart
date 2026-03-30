import 'package:flutter/material.dart';
import 'package:oembed/src/controllers/embed_controller.dart';
import 'package:oembed/src/core/oembed_scope.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/embed_loader_param.dart';
import 'package:oembed/src/models/oembed_style.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:oembed/src/services/oembed_service.dart';
import 'package:oembed/src/widgets/embed_data_loader.dart';
import 'package:oembed/src/widgets/embed_webview.dart';

class EmbedWidgetLoader extends StatelessWidget {
  const EmbedWidgetLoader({
    super.key,
    required this.param,
    required this.controller,
    this.style,
    this.scrollable = false,
  });

  final SocialEmbedParam param;
  final EmbedController controller;
  final OembedStyle? style;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final config = controller.config ?? OembedScope.configOf(context);
    final style = this.style ?? config?.style;
    final logger = config?.logger;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final showErrorWidget =
            controller.loadingState == EmbedLoadingState.error &&
            controller.didRetry;

        if (showErrorWidget) {
          final errorWidget =
              style?.errorBuilder?.call(context, null) ??
              OembedScope.delegateOf(context)?.buildSocialEmbedErrorPlaceholder(
                context: context,
                param: param,
              );
          return errorWidget ?? const Icon(Icons.error_outline);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final iframeUrl = OembedService.resolveIframeUrl(
              param.url,
              config: config,
              logger: logger,
            );

            if (iframeUrl != null) {
              return EmbedWebView.url(
                param: param,
                url: iframeUrl,
                maxWidth: constraints.maxWidth,
                controller: controller,
                scrollable: scrollable,
              );
            }

            return EmbedDataLoader(
              param: param,
              controller: controller,
              config: config,
              style: style,
              scrollable: scrollable,
              loaderParam: EmbedLoaderParam(
                url: param.url,
                embedType: param.embedType,
                width: constraints.maxWidth,
              ),
            );
          },
        );
      },
    );
  }
}
