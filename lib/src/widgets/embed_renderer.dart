import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_constraints.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_style.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_widget_loader.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/widgets/embed_surface.dart';

//
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
  final EmbedConstraints? embedConstraints;
  @Deprecated(
    'Use embedConstraints: EmbedConstraints(preferredHeight: ...) instead.',
  )
  final double? embedHeight;
  final EmbedStyle? style;
  final bool? scrollable;

  const EmbedRenderer({
    super.key,
    required this.data,
    required this.embedType,
    this.maxWidth,
    this.embedConstraints,
    this.embedHeight,
    this.style,
    this.scrollable,
  }) : assert(
          embedConstraints == null || embedHeight == null,
          'Use either embedConstraints or embedHeight, not both.',
        );

  EmbedConstraints? get _effectiveEmbedConstraints =>
      embedConstraints ??
      (embedHeight != null
          ? EmbedConstraints(preferredHeight: embedHeight)
          : null);

  @override
  Widget build(BuildContext context) {
    final config = EmbedScope.configOf(context);
    final style = this.style ?? config?.style;
    final scrollable = this.scrollable ?? config?.scrollable ?? false;

    final param = SocialEmbedParam(
      url: data.providerUrl ?? '',
      embedType: embedType,
    );

    Widget child = EmbedSurface(
      style: style,
      footerUrl: data.providerUrl ?? '',
      childBuilder: (context) => EmbedWidgetLoader(
        param: param,
        preloadedData: data,
        embedConstraints: _effectiveEmbedConstraints,
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
