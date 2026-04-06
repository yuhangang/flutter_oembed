import 'package:flutter/material.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/widgets/embed_surface.dart';

import 'package:flutter_embed/src/models/embed_tracking.dart';

/// A pure renderer for OEmbed data.
///
/// Use this widget when you already have [EmbedData] (e.g. from an API response)
/// and just want to render it without the library fetching it for you.
///
/// Unlike [EmbedCard], this widget does not require [EmbedScope] but will
/// optionally use [EmbedConfig] from it if available.
class EmbedRenderer extends StatelessWidget {
  final EmbedData data;
  final EmbedType embedType;
  final double? maxWidth;
  final EmbedTracking? tracking;
  final EmbedStyle? style;
  final bool? scrollable;

  const EmbedRenderer({
    super.key,
    required this.data,
    required this.embedType,
    this.maxWidth,
    this.tracking,
    this.style,
    this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final config = EmbedScope.configOf(context);
    final style = this.style ?? config?.style;
    final scrollable = this.scrollable ?? config?.scrollable ?? false;

    final param = SocialEmbedParam(
      url: data.providerUrl ?? '',
      embedType: embedType,
      tracking: tracking,
    );

    Widget child = EmbedSurface(
      style: style,
      footerUrl: data.providerUrl ?? '',
      childBuilder: (context) => EmbedWidgetLoader(
        param: param,
        preloadedData: data,
        style: style,
        scrollable: scrollable,
      ),
    );

    if (maxWidth != null) {
      child = Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: child,
        ),
      );
    }

    return child;
  }
}
