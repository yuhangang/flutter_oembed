import 'package:flutter/material.dart';

/// A wrapper widget that can collapse its child to a fixed height.
class ExpandableEmbed extends StatefulWidget {
  /// The embed widget to wrap.
  final Widget child;

  /// The height when collapsed.
  final double collapsedHeight;

  const ExpandableEmbed({
    super.key,
    required this.child,
    this.collapsedHeight = 150,
  });

  @override
  State<ExpandableEmbed> createState() => _ExpandableEmbedState();
}

class _ExpandableEmbedState extends State<ExpandableEmbed> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        _isExpanded ? double.infinity : widget.collapsedHeight,
                  ),
                  child: widget.child,
                ),
              ),
            ),
            if (!_isExpanded)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0),
                        Theme.of(context).colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_isExpanded ? 'Show Less' : 'Show More'),
            style: TextButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
