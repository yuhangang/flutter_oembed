import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/embed_constraints.dart';
import '../models/embed_style.dart';

/// A wrapper widget that defers rendering its [child] until it becomes visible
/// in the viewport.
///
/// It uses a [VisibilityDetector] coupled with an immediate check during
/// [initState] to accurately manage visibility even for items already onscreen.
class LazyEmbedNode extends StatefulWidget {
  final Widget child;
  final String url;
  final EmbedStyle? style;
  final EmbedConstraints? embedConstraints;

  const LazyEmbedNode({
    super.key,
    required this.child,
    required this.url,
    this.style,
    this.embedConstraints,
  });

  @override
  State<LazyEmbedNode> createState() => _LazyEmbedNodeState();
}

class _LazyEmbedNodeState extends State<LazyEmbedNode> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        VisibilityDetectorController.instance.notifyNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isVisible) {
      return widget.child;
    }

    final double fallbackHeight =
        widget.embedConstraints?.preferredHeight ?? 200.0;

    final Widget placeholder =
        widget.style?.lazyLoadPlaceholderBuilder?.call(context) ??
            widget.style?.loadingBuilder?.call(context) ??
            SizedBox(
              height: fallbackHeight,
              width: double.infinity,
              child: const Center(child: CircularProgressIndicator()),
            );

    return VisibilityDetector(
      key: const Key('lazy_embed_node_visibility_\${widget.url}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_isVisible) {
          if (mounted) {
            setState(() {
              _isVisible = true;
            });
          }
        }
      },
      child: placeholder,
    );
  }
}
