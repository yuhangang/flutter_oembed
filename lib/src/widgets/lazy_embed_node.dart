import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/core/embed_constraints.dart';
import '../models/core/embed_style.dart';

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
  final bool isInitialVisible;

  const LazyEmbedNode({
    super.key,
    required this.child,
    required this.url,
    this.style,
    this.embedConstraints,
    this.isInitialVisible = false,
  });

  @override
  State<LazyEmbedNode> createState() => _LazyEmbedNodeState();
}

class _LazyEmbedNodeState extends State<LazyEmbedNode> {
  late bool _isVisible = widget.isInitialVisible;

  @override
  void initState() {
    super.initState();
    // Schedule a visibility check after the first frame.
    // We call it twice (immediately and after a short delay) to ensure
    // that it catches the visible state even if the first one is too early.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isVisible) {
        VisibilityDetectorController.instance.notifyNow();
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && !_isVisible) {
            VisibilityDetectorController.instance.notifyNow();
          }
        });
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
      key: ValueKey('lazy_embed_node_visibility_${widget.url}'),
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
