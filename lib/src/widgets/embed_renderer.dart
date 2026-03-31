import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/widgets/embed_surface.dart';

/// A pure renderer for OEmbed data.
///
/// Use this widget when you already have [EmbedData] (e.g. from an API response)
/// and just want to render it without the library fetching it for you.
///
/// Unlike [EmbedCard], this widget does not require [EmbedScope] but will
/// optionally use [EmbedConfig] from it if available.
class EmbedRenderer extends StatefulWidget {
  final EmbedData data;
  final EmbedType embedType;
  final double? maxWidth;
  final String source;
  final EmbedStyle? style;
  final bool? scrollable;

  const EmbedRenderer({
    super.key,
    required this.data,
    required this.embedType,
    this.maxWidth,
    this.source = 'renderer',
    this.style,
    this.scrollable,
  });

  @override
  State<EmbedRenderer> createState() => _EmbedRendererState();
}

class _EmbedRendererState extends State<EmbedRenderer> {
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
    final config = EmbedScope.configOf(context);
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
