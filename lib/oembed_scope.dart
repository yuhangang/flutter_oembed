import 'package:flutter/material.dart';
import 'package:oembed/oembed_delegate.dart';

class OembedScope extends InheritedWidget {
  final OembedDelegate delegate;

  const OembedScope({
    super.key,
    required this.delegate,
    required super.child,
  });

  static OembedDelegate of(BuildContext context) {
    final OembedScope? result =
        context.dependOnInheritedWidgetOfExactType<OembedScope>();
    assert(result != null, 'No OembedScope found in context');
    return result!.delegate;
  }

  @override
  bool updateShouldNotify(OembedScope oldWidget) =>
      delegate != oldWidget.delegate;
}
