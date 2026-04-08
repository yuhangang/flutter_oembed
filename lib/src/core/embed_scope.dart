import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/base_embed_params.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';

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
  @visibleForTesting
  static BaseCacheManager cacheManager = DefaultCacheManager();

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
    await cacheManager.emptyCache();
  }

  /// Removes a single cached OEmbed response for the given content URL and request shape.
  ///
  /// Pass the same request parameters used to fetch the embed if you want to
  /// evict a width- or query-dependent cache entry precisely.
  ///
  /// Returns `true` when a matching cache key could be resolved and a removal
  /// request was issued. Returns `false` when no provider could be resolved.
  static Future<bool> evictCacheForUrl(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    double? width,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
  }) async {
    final cacheUri = EmbedService.resolveCacheUri(
      url,
      config: config,
      embedType: embedType,
      width: width,
      queryParameters: queryParameters,
      embedParams: embedParams,
    );
    if (cacheUri == null) {
      return false;
    }

    await cacheManager.removeFile(cacheUri.toString());
    return true;
  }

  /// Returns `true` when the widget should notify dependents of a change.
  ///
  /// Uses [identical] rather than `==` because [EmbedConfig] extends [Equatable]
  /// and deliberately excludes function fields (e.g. `onLinkTap`,
  /// `onNavigationRequest`, `httpClient`) from its equality check to avoid
  /// comparing closures. An identity change therefore captures all mutations,
  /// including callback-only updates.
  @override
  bool updateShouldNotify(EmbedScope oldWidget) =>
      !identical(config, oldWidget.config);
}
