import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/core/embed_service_interface.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/core/embed_constant.dart';
import 'package:flutter_oembed/src/models/configs/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/core/embed_strings.dart';
import 'package:flutter_oembed/src/models/core/embed_style.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
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
///       providers: EmbedProviders.verified
///           .where((rule) => {'YouTube', 'Spotify', 'Vimeo'}.contains(rule.providerName))
///           .toList(),
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

  /// Optional cache backend used for OEmbed response storage.
  ///
  /// Defaults to [InMemoryEmbedCacheProvider.instance].
  final EmbedCacheProvider? cacheProvider;

  /// Global visual customization. Can be overridden per-widget via [EmbedCard.style].
  final EmbedStyle? style;

  /// Facebook App ID — required for Facebook and Instagram embeds.
  final String? facebookAppId;

  /// Facebook Client Token — required for Facebook and Instagram embeds.
  final String? facebookClientToken;

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
  ///
  /// Return [NavigationDecision.prevent] to stop navigation or
  /// [NavigationDecision.navigate] to allow it.
  /// Return null to fall back to the default navigation logic.
  ///
  /// The built-in policy always allows sub-frame/bootstrap document loads,
  /// blocks unexpected main-frame redirects while the embed is still loading,
  /// and only routes post-load external navigations out of the WebView when
  /// they follow a recent user tap captured inside the embed. A Flutter-side
  /// pointer listener is also used as a coarse fallback when a provider does
  /// not expose a tappable anchor href to JavaScript.
  final FutureOr<NavigationDecision>? Function(NavigationRequest)?
      onNavigationRequest;

  /// A simpler callback for handling link clicks.
  ///
  /// If provided, this is called when the default navigation policy intercepts
  /// a user-initiated external main-frame navigation after the embed has loaded.
  ///
  /// Leaving this null makes the package attempt to open the URL via
  /// `url_launcher` using the platform's external browser or app.
  ///
  /// This is easier to use than [onNavigationRequest] as it only provides the URL.
  final void Function(String url, EmbedData? data)? onLinkTap;

  /// Timeout duration for the WebView to finish loading before showing an error.
  /// Defaults to [kDefaultEmbedLoadTimeout].
  final Duration loadTimeout;

  /// Minimum downward height change required before the controller notifies.
  ///
  /// Small DOM measurement fluctuations are common while WebViews settle. This
  /// threshold prevents visual jitter from tiny downward adjustments while
  /// still allowing immediate growth to avoid clipping.
  ///
  /// Defaults to [kDefaultHeightUpdateDeltaThreshold].
  final double heightUpdateDeltaThreshold;

  /// Whether the WebView should be scrollable internally.
  /// Defaults to `false`.
  final bool scrollable;

  /// Whether the widget should delay loading the WebView until it enters the viewport.
  /// Defaults to `false`.
  final bool lazyLoad;

  /// Whether embeds should pause media when another route covers the current route.
  ///
  /// This can pause playback when the user navigates to a new page or opens a
  /// modal bottom sheet. Requires [routeObserver] to be provided on the same
  /// [Navigator].
  final bool pauseOnRouteCover;

  /// Route observer used by embeds to subscribe to route-cover events.
  ///
  /// Pass the same observer instance to `MaterialApp.navigatorObservers` to
  /// enable route-aware media pausing.
  final RouteObserver<ModalRoute<dynamic>>? routeObserver;

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

  /// Optional custom embed service implementation.
  ///
  /// If provided, this instance will be used instead of the default [EmbedService].
  final IEmbedService? embedService;

  const EmbedConfig({
    this.providers = const EmbedProviderConfig(),
    this.cache = const EmbedCacheConfig(),
    this.cacheProvider,
    this.style,
    this.facebookAppId = '',
    this.facebookClientToken = '',
    this.proxyUrl,
    this.locale = 'en',
    this.brightness = Brightness.light,
    this.strings = const EmbedStrings(),
    this.onNavigationRequest,
    this.onLinkTap,
    this.loadTimeout = kDefaultEmbedLoadTimeout,
    this.heightUpdateDeltaThreshold = kDefaultHeightUpdateDeltaThreshold,
    this.scrollable = false,
    this.lazyLoad = false,
    this.pauseOnRouteCover = false,
    this.routeObserver,
    this.logger = const EmbedLogger.disabled(),
    this.httpClient,
    this.embedService,
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
        cacheProvider,
        style,
        facebookAppId,
        facebookClientToken,
        proxyUrl,
        locale,
        brightness,
        strings,
        loadTimeout,
        heightUpdateDeltaThreshold,
        scrollable,
        lazyLoad,
        pauseOnRouteCover,
        routeObserver,
        logger,
        embedService,
      ];

  /// Internal getter that returns the providers config.
  EmbedProviderConfig get resolvedProviders => providers;

  /// Returns `true` when all runtime-relevant fields match.
  ///
  /// Unlike [props], this comparison includes callback and client identities so
  /// widgets can distinguish a genuinely new runtime configuration from a fresh
  /// `copyWith` allocation with the same values.
  bool runtimeEquals(EmbedConfig? other) {
    if (identical(this, other)) return true;
    if (other == null) return false;
    return providers == other.providers &&
        cache == other.cache &&
        cacheProvider == other.cacheProvider &&
        style == other.style &&
        facebookAppId == other.facebookAppId &&
        facebookClientToken == other.facebookClientToken &&
        proxyUrl == other.proxyUrl &&
        locale == other.locale &&
        brightness == other.brightness &&
        strings == other.strings &&
        identical(onNavigationRequest, other.onNavigationRequest) &&
        identical(onLinkTap, other.onLinkTap) &&
        loadTimeout == other.loadTimeout &&
        heightUpdateDeltaThreshold == other.heightUpdateDeltaThreshold &&
        scrollable == other.scrollable &&
        lazyLoad == other.lazyLoad &&
        pauseOnRouteCover == other.pauseOnRouteCover &&
        routeObserver == other.routeObserver &&
        logger == other.logger &&
        identical(httpClient, other.httpClient) &&
        identical(embedService, other.embedService);
  }

  static bool runtimeEqualsNullable(EmbedConfig? a, EmbedConfig? b) {
    if (identical(a, b)) return true;
    return a?.runtimeEquals(b) ?? false;
  }

  /// Returns a copy with the given fields replaced.
  EmbedConfig copyWith({
    EmbedProviderConfig? providers,
    EmbedCacheConfig? cache,
    EmbedCacheProvider? cacheProvider,
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
    Duration? loadTimeout,
    double? heightUpdateDeltaThreshold,
    bool? scrollable,
    bool? lazyLoad,
    bool? pauseOnRouteCover,
    RouteObserver<ModalRoute<dynamic>>? routeObserver,
    EmbedLogger? logger,
    http.Client? httpClient,
    IEmbedService? embedService,
  }) {
    return EmbedConfig(
      providers: providers ?? this.providers,
      cache: cache ?? this.cache,
      cacheProvider: cacheProvider ?? this.cacheProvider,
      style: style ?? this.style,
      facebookAppId: facebookAppId ?? this.facebookAppId,
      facebookClientToken: facebookClientToken ?? this.facebookClientToken,
      proxyUrl: proxyUrl ?? this.proxyUrl,
      locale: locale ?? this.locale,
      brightness: brightness ?? this.brightness,
      strings: strings ?? this.strings,
      onNavigationRequest: onNavigationRequest ?? this.onNavigationRequest,
      onLinkTap: onLinkTap ?? this.onLinkTap,
      loadTimeout: loadTimeout ?? this.loadTimeout,
      heightUpdateDeltaThreshold:
          heightUpdateDeltaThreshold ?? this.heightUpdateDeltaThreshold,
      scrollable: scrollable ?? this.scrollable,
      lazyLoad: lazyLoad ?? this.lazyLoad,
      pauseOnRouteCover: pauseOnRouteCover ?? this.pauseOnRouteCover,
      routeObserver: routeObserver ?? this.routeObserver,
      logger: logger ?? this.logger,
      httpClient: httpClient ?? this.httpClient,
      embedService: embedService ?? this.embedService,
    );
  }
}
