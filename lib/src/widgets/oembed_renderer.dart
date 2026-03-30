import 'package:flutter/material.dart';
import 'package:oembed/src/controllers/embed_controller.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:oembed/src/models/oembed_style.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:oembed/src/widgets/embed_widget_loader.dart';
import 'package:oembed/src/core/oembed_scope.dart';
import 'package:oembed/src/widgets/embed_surface.dart';

/// A pure renderer for OEmbed data.
///
/// Use this widget when you already have [OembedData] (e.g. from an API response)
/// and just want to render it without the library fetching it for you.
///
/// Unlike [EmbedCard], this widget does not require [OembedScope] but will
/// optionally use [OembedConfig] from it if available.
class OembedRenderer extends StatefulWidget {
  final OembedData data;
  final EmbedType embedType;
  final double? maxWidth;
  final String source;
  final OembedStyle? style;
  final bool? scrollable;

  const OembedRenderer({
    super.key,
    required this.data,
    required this.embedType,
    this.maxWidth,
    this.source = 'renderer',
    this.style,
    this.scrollable,
  });

  @override
  State<OembedRenderer> createState() => _OembedRendererState();
}

class _OembedRendererState extends State<OembedRenderer> {
  late final EmbedController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EmbedController(
      param: SocialEmbedParam(
        url: widget.data.providerUrl ?? '',
        embedType: widget.embedType,
        source: widget.source,
        contentId: '',
        pageIdentifier: '',
        elementId: '',
        extraIdentifier: '',
      ),
      preloadedData: widget.data,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = OembedScope.configOf(context);
    final style = widget.style ?? config?.style;
    final scrollable = widget.scrollable ?? config?.scrollable ?? false;

    return EmbedSurface(
      style: style,
      footerUrl: widget.data.providerUrl ?? '',
      childBuilder:
          (context) => EmbedWidgetLoader(
            param: _controller.param,
            controller: _controller,
            style: style,
            scrollable: scrollable,
          ),
    );
  }
}
