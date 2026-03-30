import 'package:oembed/src/models/provider_rule.dart';
import 'package:oembed/src/services/provider_registry.dart';
import 'package:oembed/src/services/providers_snapshot.dart';

/// Controls which OEmbed providers are active and how they render content.
class OembedProviderConfig {
  /// Whitelisted provider names. When non-null, only these providers are used.
  /// Names match [OembedProviderRule.providerName] (case-sensitive).
  ///
  /// Set to `null` to enable all built-in providers (default).
  ///
  /// Example:
  /// ```dart
  /// enabledProviders: {'Spotify', 'Vimeo', 'YouTube'},
  /// ```
  final Set<String>? enabledProviders;

  /// Per-provider render mode overrides.
  ///
  /// When a provider is mapped to [OembedRenderMode.iframe], the library will
  /// use the provider's [OembedProviderRule.iframeUrlBuilder] to construct an
  /// iframe src URL directly, skipping the OEmbed API call entirely.
  ///
  /// Example:
  /// ```dart
  /// providerRenderModes: {
  ///   'YouTube': OembedRenderMode.iframe,
  ///   'Spotify': OembedRenderMode.iframe,
  /// },
  /// ```
  final Map<String, OembedRenderMode> providerRenderModes;

  /// Additional custom provider rules appended after the built-in list.
  final List<OembedProviderRule> customProviders;

  /// Whether to include dynamically discovered rules from the official registry.
  final bool useDynamicDiscovery;

  /// Whether to include unverified/untested built-in providers.
  /// Defaults to `false` (only verified providers are active by default).
  final bool includeUnverified;

  const OembedProviderConfig({
    this.enabledProviders,
    this.providerRenderModes = const {},
    this.customProviders = const [],
    this.useDynamicDiscovery = false,
    this.includeUnverified = false,
  });

  /// Returns true if the given provider should be used.
  bool isEnabled(String providerName) {
    if (enabledProviders == null) return true;
    return enabledProviders!.contains(providerName);
  }

  /// Returns the render mode for the given provider. Defaults to
  /// [OembedRenderMode.oembed] if not explicitly overridden.
  OembedRenderMode getRenderMode(String providerName) {
    return providerRenderModes[providerName] ?? OembedRenderMode.oembed;
  }

  /// Returns a copy of this configuration with the given fields replaced.
  OembedProviderConfig copyWith({
    Set<String>? enabledProviders,
    Map<String, OembedRenderMode>? providerRenderModes,
    List<OembedProviderRule>? customProviders,
    bool? useDynamicDiscovery,
    bool? includeUnverified,
  }) {
    return OembedProviderConfig(
      enabledProviders: enabledProviders ?? this.enabledProviders,
      providerRenderModes: providerRenderModes ?? this.providerRenderModes,
      customProviders: customProviders ?? this.customProviders,
      useDynamicDiscovery: useDynamicDiscovery ?? this.useDynamicDiscovery,
      includeUnverified: includeUnverified ?? this.includeUnverified,
    );
  }

  /// Returns the full merged provider list (built-in + custom + dynamic) filtered by
  /// [enabledProviders].
  List<OembedProviderRule> get effectiveProviders {
    final Iterable<OembedProviderRule> discoveryRules =
        useDynamicDiscovery
            ? kOembedProvidersSnapshot.values.expand((e) => e)
            : const [];

    final all = <OembedProviderRule>[
      ...customProviders,
      ...kDefaultOembedProviders,
      ...discoveryRules,
    ];

    final filtered =
        all.where((r) {
          if (includeUnverified) return true;
          // If it's a custom provider or dynamic discovery, we assume verification
          // is handled by the source or is intentional.
          // Actually, we should probably only filter kDefaultOembedProviders.
          if (customProviders.contains(r) || discoveryRules.contains(r)) {
            return true;
          }
          return r.isVerified;
        }).toList();

    if (enabledProviders == null) return filtered;
    return filtered
        .where((r) => enabledProviders!.contains(r.providerName))
        .toList();
  }
}

/// Determines how embed content is rendered.
enum OembedRenderMode {
  /// Fetch embed HTML via the OEmbed API and render it in a WebView.
  oembed,

  /// Build an iframe src URL directly (using [OembedProviderRule.iframeUrlBuilder])
  /// and load it in a WebView, skipping the OEmbed API entirely.
  iframe,
}
