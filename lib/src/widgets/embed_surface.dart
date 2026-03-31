import 'package:flutter/material.dart';
import 'package:flutter_embed/src/models/embed_style.dart';

/// Shared presentation shell for embed widgets.
///
/// This keeps wrapper, border radius, and footer application consistent across
/// the different public entry points.
class EmbedSurface extends StatelessWidget {
  final WidgetBuilder childBuilder;
  final EmbedStyle? style;
  final String footerUrl;
  final Widget Function(BuildContext context, Widget child)?
  fallbackWrapperBuilder;

  const EmbedSurface({
    super.key,
    required this.childBuilder,
    this.style,
    this.footerUrl = '',
    this.fallbackWrapperBuilder,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = childBuilder(context);

    if (style?.wrapperBuilder != null) {
      child = style!.wrapperBuilder!(context, child);
    } else if (fallbackWrapperBuilder != null) {
      child = fallbackWrapperBuilder!(context, child);
    } else if (style?.borderRadius != null) {
      child = ClipRRect(borderRadius: style!.borderRadius!, child: child);
    }

    if (style?.footerBuilder != null) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child, style!.footerBuilder!(context, footerUrl)],
      );
    }

    return child;
  }
}
