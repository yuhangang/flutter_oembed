import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_style.dart';

/// Provides [EmbedConfig] to the widget subtree.
///
/// ```dart
/// // Setup
/// EmbedScope(
///   config: EmbedConfig(
///     facebookAppId: 'YOUR_APP_ID',
///     facebookClientToken: 'YOUR_CLIENT_TOKEN',
///     cache: EmbedCacheConfig(enabled: false),
///   ),
///   child: ...,
/// )
/// ```
class EmbedScope extends InheritedWidget {
  final EmbedConfig config;

  const EmbedScope({
    super.key,
    required this.config,
    required super.child,
  });

  static EmbedScope? _maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<EmbedScope>();
    }
    return context.getElementForInheritedWidgetOfExactType<EmbedScope>()?.widget
        as EmbedScope?;
  }

  /// Returns the [EmbedConfig] from the nearest [EmbedScope], or null.
  static EmbedConfig? configOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.config;
  }

  /// Returns the [EmbedStyle] from the nearest [EmbedScope], or null.
  ///
  /// Prefer this over extracting style from `configOf(context)?.style` for readability.
  static EmbedStyle? styleOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.config.style;
  }

  /// Clears all cached OEmbed data from the persistent storage.
  static Future<void> clearCache() async {
    await DefaultCacheManager().emptyCache();
  }

  @override
  bool updateShouldNotify(EmbedScope oldWidget) => config != oldWidget.config;
}
