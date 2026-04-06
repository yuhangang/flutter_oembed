import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter_embed/src/core/embed_delegate.dart';
import 'package:flutter_embed/src/core/simple_embed_delegate.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_style.dart';

/// Provides [EmbedConfig] and/or [EmbedDelegate] to the widget subtree.
///
/// At least one of [config] or [delegate] must be provided.
///
/// ```dart
/// // Simple setup — no delegate needed
/// EmbedScope(
///   config: EmbedConfig(
///     facebookAppId: 'YOUR_APP_ID',
///     facebookClientToken: 'YOUR_CLIENT_TOKEN',
///     cache: EmbedCacheConfig(enabled: false),
///   ),
///   child: ...,
/// )
///
/// // Legacy setup (still supported)
/// EmbedScope(
///   delegate: myDelegate,
///   child: ...,
/// )
/// ```
class EmbedScope extends InheritedWidget {
  final EmbedDelegate? delegate;
  final EmbedConfig? config;

  const EmbedScope({
    super.key,
    this.delegate,
    this.config,
    required super.child,
  }) : assert(
          delegate != null || config != null,
          'EmbedScope requires at least one of delegate or config.',
        );

  static EmbedScope? _maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<EmbedScope>();
    }
    return context
        .getElementForInheritedWidgetOfExactType<EmbedScope>()
        ?.widget as EmbedScope?;
  }

  static EmbedDelegate of(BuildContext context, {bool listen = true}) {
    final scope = _maybeOf(context, listen: listen);
    assert(scope != null, 'No EmbedScope found in context');
    return scope?.delegate ?? const SimpleEmbedDelegate();
  }

  /// Returns the [EmbedConfig] from the nearest [EmbedScope], or null.
  static EmbedConfig? configOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.config;
  }

  /// Returns the [EmbedDelegate] from the nearest [EmbedScope], or null.
  static EmbedDelegate? delegateOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.delegate;
  }

  /// Returns the [EmbedStyle] from the nearest [EmbedScope], or null.
  ///
  /// Prefer this over extracting style from `configOf(context)?.style` for readability.
  static EmbedStyle? styleOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.config?.style;
  }

  /// Clears all cached OEmbed data from the persistent storage.
  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }

  @override
  bool updateShouldNotify(EmbedScope oldWidget) =>
      delegate != oldWidget.delegate || config != oldWidget.config;
}
