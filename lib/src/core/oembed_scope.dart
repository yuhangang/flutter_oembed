import 'package:flutter/material.dart';
import 'package:oembed/src/core/oembed_delegate.dart';
import 'package:oembed/src/core/simple_oembed_delegate.dart';
import 'package:oembed/src/models/oembed_config.dart';
import 'package:oembed/src/models/oembed_style.dart';

/// Provides [OembedConfig] and/or [OembedDelegate] to the widget subtree.
///
/// At least one of [config] or [delegate] must be provided.
///
/// ```dart
/// // Simple setup — no delegate needed
/// OembedScope(
///   config: OembedConfig(
///     facebookAppId: 'YOUR_APP_ID',
///     facebookClientToken: 'YOUR_CLIENT_TOKEN',
///     cache: OembedCacheConfig(enabled: false),
///   ),
///   child: ...,
/// )
///
/// // Legacy setup (still supported)
/// OembedScope(
///   delegate: myDelegate,
///   child: ...,
/// )
/// ```
class OembedScope extends InheritedWidget {
  final OembedDelegate? delegate;
  final OembedConfig? config;

  const OembedScope({
    super.key,
    this.delegate,
    this.config,
    required super.child,
  }) : assert(
          delegate != null || config != null,
          'OembedScope requires at least one of delegate or config.',
        );

  static OembedScope? _maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OembedScope>();
  }

  static OembedDelegate of(BuildContext context) {
    final scope = _maybeOf(context);
    assert(scope != null, 'No OembedScope found in context');
    return scope?.delegate ?? const SimpleOembedDelegate();
  }

  /// Returns the [OembedConfig] from the nearest [OembedScope], or null.
  static OembedConfig? configOf(BuildContext context) {
    return _maybeOf(context)?.config;
  }

  /// Returns the [OembedDelegate] from the nearest [OembedScope], or null.
  static OembedDelegate? delegateOf(BuildContext context) {
    return _maybeOf(context)?.delegate;
  }

  /// Returns the [OembedStyle] from the nearest [OembedScope], or null.
  ///
  /// Prefer this over extracting style from `configOf(context)?.style` for readability.
  static OembedStyle? styleOf(BuildContext context) {
    return _maybeOf(context)?.config?.style;
  }

  @override
  bool updateShouldNotify(OembedScope oldWidget) =>
      delegate != oldWidget.delegate || config != oldWidget.config;
}
