import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';
import 'package:flutter_oembed/src/models/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/embed_strings.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

/// Unified configuration for the OEmbed library.
///
/// Pass this to [EmbedScope] to configure the entire embed system in one place.
///
/// ```dart
/// EmbedScope(
///   config: EmbedConfig(
///     facebookAppId: 'YOUR_APP_ID',
///     facebookClientToken: 'YOUR_CLIENT_TOKEN',
///     cache: EmbedCacheConfig(enabled: false),
///     providers: EmbedProviderConfig(
///       enabledProviders: {'YouTube', 'Spotify', 'Vimeo'},
///       providerRenderModes: {
///         'YouTube': EmbedRenderMode.iframe,
///       },
///     ),
///     style: EmbedStyle(
///       borderRadius: BorderRadius.circular(12),
///       footerBuilder: (context, url) => TextButton(
///         child: Text('Open link'),
///         onPressed: () => launchUrl(Uri.parse(url)),
///       ),
///     ),
///   ),
///   child: ...,
/// )
/// ```
class EmbedConfig extends Equatable {
  /// Provider registry — controls which providers are active and how they render.
  final EmbedProviderConfig providers;

  /// Cache settings.
  final EmbedCacheConfig cache;

  /// Global visual customization. Can be overridden per-widget via [EmbedCard.style].
  final EmbedStyle? style;

  /// Facebook App ID — required for Facebook and Instagram embeds.
  final String facebookAppId;

  /// Facebook Client Token — required for Facebook and Instagram embeds.
  final String facebookClientToken;

  /// Optional proxy URL to route API requests (e.g. Meta) through.
  /// If provided, [facebookAppId] and [facebookClientToken] become optional.
  final String? proxyUrl;

  /// BCP-47 locale code passed to provider APIs that support localisation.
  final String locale;

  /// App brightness, forwarded to providers that support theme switching.
  ///
  /// Currently this is honored by X, Reddit, and [YoutubeEmbedPlayer].
  /// Other built-in providers may ignore it because their upstream embed APIs
  /// do not expose a stable theme parameter.
  final Brightness brightness;

  /// User-facing copy used by package-provided loading, retry, and semantics.
  final EmbedStrings strings;

  /// Custom navigation request handler.
  /// If provided, this is called before the default navigation logic.
  /// Return [NavigationDecision.prevent] to stop navigation or [NavigationDecision.navigate] to allow it.
  /// Return null to fall back to the default navigation logic.
  final FutureOr<NavigationDecision>? Function(NavigationRequest)?
      onNavigationRequest;

  /// A simpler callback for handling link clicks.
  /// If provided, this is called when a user clicks a link inside the embed.
  /// Defaults to null. Leaving this null will just log a warning when clicked.
  ///
  /// This is easier to use than [onNavigationRequest] as it only provides the URL.
  final void Function(String url, EmbedData? data)? onLinkTap;

  /// Whether to use dynamic discovery via the official OEmbed providers.json registry.
  /// Defaults to `false`.
  final bool useDynamicDiscovery;

  /// Timeout duration for the WebView to finish loading before showing an error.
  /// Defaults to [kDefaultEmbedLoadTimeout].
  final Duration loadTimeout;

  /// Whether the WebView should be scrollable internally.
  /// Defaults to `false`.
  final bool scrollable;

  /// Optional logger used by the library to emit provider resolution, cache,
  /// navigation, and loading diagnostics.
  ///
  /// Use [EmbedLogger.debug] to print debug-only logs to the console, or
  /// [EmbedLogger.enabled] with a custom sink to forward logs elsewhere.
  final EmbedLogger logger;

  /// Optional HTTP client used to fetch OEmbed data.
  ///
  /// This is useful for testing or providing custom configurations (e.g., custom headers).
  final http.Client? httpClient;

  const EmbedConfig({
    this.providers = const EmbedProviderConfig(),
    this.cache = const EmbedCacheConfig(),
    this.style,
    this.facebookAppId = '',
    this.facebookClientToken = '',
    this.proxyUrl,
    this.locale = 'en',
    this.brightness = Brightness.light,
    this.strings = const EmbedStrings(),
    this.onNavigationRequest,
    this.onLinkTap,
    this.useDynamicDiscovery = false,
    this.loadTimeout = kDefaultEmbedLoadTimeout,
    this.scrollable = false,
    this.logger = const EmbedLogger.disabled(),
    this.httpClient,
  });

  /// Equality props — intentionally excludes function fields.
  ///
  /// [onNavigationRequest], [onLinkTap], and [httpClient] are omitted because
  /// Dart closures do not implement value equality: two identical lambdas are
  /// never `==`. Excluding them avoids false "equal" results from Equatable.
  ///
  /// [EmbedScope.updateShouldNotify] compensates by using [identical] instead
  /// of `==`, so replacing the whole [EmbedConfig] (even with the same field
  /// values but a new closure) will still trigger a rebuild.
  @override
  List<Object?> get props => [
        providers,
        cache,
        style,
        facebookAppId,
        facebookClientToken,
        proxyUrl,
        locale,
        brightness,
        strings,
        useDynamicDiscovery,
        loadTimeout,
        scrollable,
        logger,
      ];

  /// Internal getter that returns the providers config with the discovery flag synced.
  EmbedProviderConfig get resolvedProviders =>
      providers.useDynamicDiscovery == useDynamicDiscovery
          ? providers
          : providers.copyWith(useDynamicDiscovery: useDynamicDiscovery);

  /// Returns a copy with the given fields replaced.
  EmbedConfig copyWith({
    EmbedProviderConfig? providers,
    EmbedCacheConfig? cache,
    EmbedStyle? style,
    String? facebookAppId,
    String? facebookClientToken,
    String? proxyUrl,
    String? locale,
    Brightness? brightness,
    EmbedStrings? strings,
    FutureOr<NavigationDecision>? Function(NavigationRequest)?
        onNavigationRequest,
    void Function(String url, EmbedData? data)? onLinkTap,
    bool? useDynamicDiscovery,
    Duration? loadTimeout,
    bool? scrollable,
    EmbedLogger? logger,
    http.Client? httpClient,
  }) {
    return EmbedConfig(
      providers: providers ?? this.providers,
      cache: cache ?? this.cache,
      style: style ?? this.style,
      facebookAppId: facebookAppId ?? this.facebookAppId,
      facebookClientToken: facebookClientToken ?? this.facebookClientToken,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      locale: locale ?? this.locale,
      brightness: brightness ?? this.brightness,
      strings: strings ?? this.strings,
      onNavigationRequest: onNavigationRequest ?? this.onNavigationRequest,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      useDynamicDiscovery: useDynamicDiscovery ?? this.useDynamicDiscovery,
      loadTimeout: loadTimeout ?? this.loadTimeout,
      scrollable: scrollable ?? this.scrollable,
      logger: logger ?? this.logger,
      httpClient: httpClient ?? this.httpClient,
    );
  }
}
