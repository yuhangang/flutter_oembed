import 'package:oembed/data/embed_widget_loader.dart';
import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:oembed/domain/entities/social_embed_param.dart';
import 'package:oembed/utils/embed_link_utils.dart';
import 'package:flutter/material.dart';
import 'package:oembed/oembed_scope.dart';
import 'package:oembed/application/embed_controller.dart';

class EmbedCard extends StatefulWidget {
  final String url;
  final EmbedType embedType;
  final EmbedContentType embedContentType;
  final String source;
  final String pageIdentifier;
  final String contentId;
  final String? elementId;
  final String extraIdentifier;
  final EmbedController? controller;

  const EmbedCard({
    super.key,
    required this.url,
    required this.embedType,
    required this.embedContentType,
    required this.pageIdentifier,
    required this.source,
    required this.contentId,
    required this.elementId,
    required this.extraIdentifier,
    this.controller,
  });

  @override
  State<EmbedCard> createState() => _EmbedCardState();
}

class _EmbedCardState extends State<EmbedCard> {
  late final SocialEmbedParam param = SocialEmbedParam(
    url: widget.embedType == EmbedType.youtube
        ? getYoutubeEmbedParam(widget.url)
        : widget.url,
    embedType: widget.embedType,
    embedContentType: widget.embedContentType,
    source: widget.source,
    contentId: widget.contentId,
    pageIdentifier: widget.pageIdentifier,
    elementId: widget.elementId,
    extraIdentifier: widget.extraIdentifier,
  );

  EmbedController? _internalController;
  EmbedController get _controller => widget.controller ?? _internalController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller == null && _internalController == null) {
      _internalController = EmbedController(
        param: param,
        delegate: OembedScope.of(context),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted && widget.embedType != EmbedType.youtube) {
        OembedScope.of(context).initEmbedPost(
             param.url,
        );
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
    if (param.embedType == EmbedType.youtube) {
      return OembedScope.of(context).buildSocialEmbedLinkWrapper(
        context: context,
        param: param,
        child: OembedScope.of(context).buildYoutubeVideoCard(
          context: context,
          param: param,
          source: widget.source,
        ),
      );
    }

    return OembedScope.of(context).buildSocialEmbedLinkWrapper(
      context: context,
      param: param,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shownEmbed = OembedScope.of(context).showSocialEmbed(
            widget.pageIdentifier,
            param.url,
          );

          if (shownEmbed) {
            return EmbedWidgetLoader(
              param: param,
              controller: _controller,
            );
          }
          return OembedScope.of(context).buildSocialEmbedLoadButton(
            context: context,
            param: param,
            identifier: widget.pageIdentifier,
          );
        },
      ),
    );
  }
}
