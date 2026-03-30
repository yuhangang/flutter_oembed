import 'package:flutter/material.dart';
import 'package:oembed/src/models/oembed_cache_config.dart';
import 'package:oembed/src/models/oembed_provider_config.dart';
import 'package:oembed/src/models/oembed_style.dart';
import 'package:oembed/src/logging/oembed_logger.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

/// Unified configuration for the OEmbed library.
///
/// Pass this to [OembedScope] to configure the entire embed system in one place.
///
/// ```dart
/// OembedScope(
///   config: OembedConfig(
///     facebookAppId: 'YOUR_APP_ID',
///     facebookClientToken: 'YOUR_CLIENT_TOKEN',
///     cache: OembedCacheConfig(enabled: false),
///     providers: OembedProviderConfig(
///       enabledProviders: {'YouTube', 'Spotify', 'Vimeo'},
///       providerRenderModes: {
///         'YouTube': OembedRenderMode.iframe,
///       },
///     ),
///     style: OembedStyle(
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
class OembedConfig {
  /// Provider registry — controls which providers are active and how they render.
  final OembedProviderConfig providers;

  /// Cache settings.
  final OembedCacheConfig cache;

  /// Global visual customization. Can be overridden per-widget via [EmbedCard.style].
  final OembedStyle? style;

  /// Facebook App ID — required for Facebook and Instagram embeds.
  final String facebookAppId;

  /// Facebook Client Token — required for Facebook and Instagram embeds.
  final String facebookClientToken;

  /// Optional proxy URL to route API requests (e.g. Meta) through.
  /// If provided, [facebookAppId] and [facebookClientToken] become optional.
  final String? proxyUrl;

  /// BCP-47 locale code passed to provider APIs that support localisation.
  final String locale;

  /// App brightness, forwarded to providers that support theme switching (e.g. X/Twitter).
  final Brightness brightness;

  /// Custom navigation request handler.
  /// If provided, this is called before the default navigation logic.
  /// Return [NavigationDecision.prevent] to stop navigation or [NavigationDecision.navigate] to allow it.
  /// Return null to fall back to the default navigation logic.
  final FutureOr<NavigationDecision>? Function(NavigationRequest)?
  onNavigationRequest;

  /// A simpler callback for handling link clicks.
  /// If provided, this is called when a user clicks a link that would normally
  /// trigger [OembedDelegate.openSocialEmbedLinkClick].
  ///
  /// This is easier to use than [onNavigationRequest] as it only provides the URL.
  final void Function(String url, OembedData? data)? onLinkTap;

  /// Whether to use dynamic discovery via the official OEmbed providers.json registry.
  /// Defaults to `false`.
  final bool useDynamicDiscovery;

  /// Timeout duration for the WebView to finish loading before showing an error.
  /// Defaults to 10 seconds.
  final Duration loadTimeout;

  /// Whether the WebView should be scrollable internally.
  /// Defaults to `false`.
  final bool scrollable;

  /// Optional logger used by the library to emit provider resolution, cache,
  /// navigation, and loading diagnostics.
  ///
  /// Use [OembedLogger.debug] to print debug-only logs to the console, or
  /// [OembedLogger.enabled] with a custom sink to forward logs elsewhere.
  final OembedLogger logger;

  const OembedConfig({
    this.providers = const OembedProviderConfig(),
    this.cache = const OembedCacheConfig(),
    this.style,
    this.facebookAppId = '',
    this.facebookClientToken = '',
    this.proxyUrl,
    this.locale = 'en',
    this.brightness = Brightness.light,
    this.onNavigationRequest,
    this.onLinkTap,
    this.useDynamicDiscovery = false,
    this.loadTimeout = const Duration(seconds: 10),
    this.scrollable = false,
    this.logger = const OembedLogger.disabled(),
  });

  /// Internal getter that returns the providers config with the discovery flag synced.
  OembedProviderConfig get resolvedProviders =>
      providers.useDynamicDiscovery == useDynamicDiscovery
          ? providers
          : providers.copyWith(useDynamicDiscovery: useDynamicDiscovery);

  /// Returns a copy with the given fields replaced.
  OembedConfig copyWith({
    OembedProviderConfig? providers,
    OembedCacheConfig? cache,
    OembedStyle? style,
    String? facebookAppId,
    String? facebookClientToken,
    String? proxyUrl,
    String? locale,
    Brightness? brightness,
    FutureOr<NavigationDecision>? Function(NavigationRequest)?
    onNavigationRequest,
    void Function(String url, OembedData? data)? onLinkTap,
    bool? useDynamicDiscovery,
    Duration? loadTimeout,
    bool? scrollable,
    OembedLogger? logger,
  }) {
    return OembedConfig(
      providers: providers ?? this.providers,
      cache: cache ?? this.cache,
      style: style ?? this.style,
      facebookAppId: facebookAppId ?? this.facebookAppId,
      facebookClientToken: facebookClientToken ?? this.facebookClientToken,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      locale: locale ?? this.locale,
      brightness: brightness ?? this.brightness,
      onNavigationRequest: onNavigationRequest ?? this.onNavigationRequest,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      useDynamicDiscovery: useDynamicDiscovery ?? this.useDynamicDiscovery,
      loadTimeout: loadTimeout ?? this.loadTimeout,
      scrollable: scrollable ?? this.scrollable,
      logger: logger ?? this.logger,
    );
  }
}
