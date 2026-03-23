import 'package:oembed/application/embed_controller.dart';
import 'package:oembed/data/embed_data_loader.dart';
import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:oembed/domain/entities/embed_loader_param.dart';
import 'package:oembed/domain/entities/social_embed_param.dart';
import 'package:oembed/presentation/embed_webview.dart';
import 'package:oembed/oembed_scope.dart';
import 'package:oembed/utils/embed_link_utils.dart';
import 'package:flutter/material.dart';

class EmbedWidgetLoader extends StatelessWidget {
  const EmbedWidgetLoader({
    super.key,
    required this.param,
    required this.controller,
  });

  final SocialEmbedParam param;
  final EmbedController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final showErrorWidget = controller.loadingState == EmbedLoadingState.error && controller.didRetry;

        if (showErrorWidget) {
          return OembedScope.of(context).buildSocialEmbedErrorPlaceholder(context: context, param: param);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (param.embedType == EmbedType.tiktok) {
              final embedUrl = getTikTokEmbedUrl(param.url);

              if (embedUrl != null) {
                return EmbedWebView.url(
                  param: param,
                  url: embedUrl,
                  maxWidth: constraints.maxWidth,
                  controller: controller,
                );
              } else {
                return OembedScope.of(context).buildSocialEmbedErrorPlaceholder(context: context, param: param);
              }
            }

            return EmbedDataLoader(
              param: param,
              controller: controller,
              loaderParam: EmbedLoaderParam(
                url: param.url,
                embedType: param.embedType,
                width: constraints.maxWidth,
              ),
            );
          },
        );
      }
    );
  }
}
