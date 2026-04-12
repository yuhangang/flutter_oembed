import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/models/base_embed_params.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/services/default_embed_cache_provider.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
class EmbedScope extends StatefulWidget {
  final EmbedConfig config;

  /// Enables opt-in WebView controller reuse for embeds in this subtree.
  ///
  /// Reuse is still disabled unless individual embeds provide a `reuseKey`.
  final bool reuseWebViews;

  const EmbedScope({
    super.key,
    required this.config,
    this.reuseWebViews = false,
    required this.child,
  });

  final Widget child;

  static _EmbedScopeInherited? _maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<_EmbedScopeInherited>();
    }
    return context
        .getElementForInheritedWidgetOfExactType<_EmbedScopeInherited>()
        ?.widget as _EmbedScopeInherited?;
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

  /// Returns whether the nearest [EmbedScope] allows controller reuse.
  static bool reuseWebViewsOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.reuseWebViews ?? false;
  }

  static WebViewController? takeReusedWebViewController(
    BuildContext context, {
    required Object reuseKey,
    required Object signature,
  }) {
    return takeReusedWebViewControllerFromToken(
      reuseScopeTokenOf(context, listen: false),
      reuseKey: reuseKey,
      signature: signature,
    );
  }

  static Object? reuseScopeTokenOf(BuildContext context, {bool listen = true}) {
    return _maybeOf(context, listen: listen)?.state;
  }

  static WebViewController? takeReusedWebViewControllerFromToken(
    Object? scopeToken, {
    required Object reuseKey,
    required Object signature,
  }) {
    final state = scopeToken is _EmbedScopeState ? scopeToken : null;
    if (state == null || !state.widget.reuseWebViews) return null;
    return state._takeReusedWebViewController(
      reuseKey: reuseKey,
      signature: signature,
    );
  }

  static void releaseReusedWebViewController(
    BuildContext context, {
    required Object reuseKey,
    required Object signature,
    required WebViewController controller,
  }) {
    releaseReusedWebViewControllerToToken(
      reuseScopeTokenOf(context, listen: false),
      reuseKey: reuseKey,
      signature: signature,
      controller: controller,
    );
  }

  static void releaseReusedWebViewControllerToToken(
    Object? scopeToken, {
    required Object reuseKey,
    required Object signature,
    required WebViewController controller,
  }) {
    final state = scopeToken is _EmbedScopeState ? scopeToken : null;
    if (state == null || !state.widget.reuseWebViews) return;
    state._releaseReusedWebViewController(
      reuseKey: reuseKey,
      signature: signature,
      controller: controller,
    );
  }

  /// Clears all cached OEmbed data from the persistent storage.
  ///
  /// Pass [config] to clear the cache backend associated with that scope.
  /// When omitted, the package default cache provider is used.
  static Future<void> clearCache({
    EmbedConfig? config,
    EmbedCacheProvider? cacheProvider,
  }) async {
    await _resolveCacheProvider(
      config: config,
      cacheProvider: cacheProvider,
    ).emptyCache();
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
    EmbedCacheProvider? cacheProvider,
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

    await _resolveCacheProvider(
      config: config,
      cacheProvider: cacheProvider,
    ).removeFile(cacheUri.toString());
    return true;
  }

  static EmbedCacheProvider _resolveCacheProvider({
    EmbedConfig? config,
    EmbedCacheProvider? cacheProvider,
  }) {
    return cacheProvider ??
        config?.cacheProvider ??
        DefaultEmbedCacheProvider.instance;
  }

  /// Returns `true` when the widget should notify dependents of a change.
  ///
  /// Uses [identical] rather than `==` because [EmbedConfig] extends [Equatable]
  /// and deliberately excludes function fields (e.g. `onLinkTap`,
  /// `onNavigationRequest`, `httpClient`) from its equality check to avoid
  /// comparing closures. An identity change therefore captures all mutations,
  /// including callback-only updates.
  bool updateShouldNotify(EmbedScope oldWidget) {
    return !identical(config, oldWidget.config) ||
        reuseWebViews != oldWidget.reuseWebViews;
  }

  @override
  State<EmbedScope> createState() => _EmbedScopeState();
}

class _EmbedScopeState extends State<EmbedScope> {
  final Map<Object, _ReusedWebViewControllerEntry> _reusedControllers =
      <Object, _ReusedWebViewControllerEntry>{};

  WebViewController? _takeReusedWebViewController({
    required Object reuseKey,
    required Object signature,
  }) {
    final entry = _reusedControllers.remove(reuseKey);
    if (entry == null) return null;
    if (entry.signature != signature) return null;
    return entry.controller;
  }

  void _releaseReusedWebViewController({
    required Object reuseKey,
    required Object signature,
    required WebViewController controller,
  }) {
    _reusedControllers[reuseKey] = _ReusedWebViewControllerEntry(
      signature: signature,
      controller: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EmbedScopeInherited(
      config: widget.config,
      reuseWebViews: widget.reuseWebViews,
      state: this,
      child: widget.child,
    );
  }
}

class _EmbedScopeInherited extends InheritedWidget {
  const _EmbedScopeInherited({
    required this.config,
    required this.reuseWebViews,
    required this.state,
    required super.child,
  });

  final EmbedConfig config;
  final bool reuseWebViews;
  final _EmbedScopeState state;

  @override
  bool updateShouldNotify(_EmbedScopeInherited oldWidget) {
    return !identical(config, oldWidget.config) ||
        reuseWebViews != oldWidget.reuseWebViews;
  }
}

class _ReusedWebViewControllerEntry {
  const _ReusedWebViewControllerEntry({
    required this.signature,
    required this.controller,
  });

  final Object signature;
  final WebViewController controller;
}
