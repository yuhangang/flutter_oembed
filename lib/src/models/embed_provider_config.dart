import 'package:equatable/equatable.dart';
import 'package:flutter_oembed/src/models/provider_rule.dart';
import 'package:flutter_oembed/src/services/provider_registry.dart';
import 'package:flutter_oembed/src/services/providers_snapshot.dart';

/// Controls which OEmbed providers are active and how they render content.
class EmbedProviderConfig extends Equatable {
  /// Whitelisted provider names. When non-null, only these providers are used.
  /// Names match [EmbedProviderRule.providerName] (case-sensitive).
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
  /// When a provider is mapped to [EmbedRenderMode.iframe], the library will
  /// use the provider's [EmbedProviderRule.iframeUrlBuilder] to construct an
  /// iframe src URL directly, skipping the OEmbed API call entirely.
  ///
  /// Example:
  /// ```dart
  /// providerRenderModes: {
  ///   'YouTube': EmbedRenderMode.iframe,
  ///   'Spotify': EmbedRenderMode.iframe,
  /// },
  /// ```
  final Map<String, EmbedRenderMode> providerRenderModes;

  /// Additional custom provider rules appended after the built-in list.
  final List<EmbedProviderRule> customProviders;

  /// Whether to include dynamically discovered rules from the official registry.
  final bool useDynamicDiscovery;

  /// Whether to include unverified/untested built-in providers.
  /// Defaults to `false` (only verified providers are active by default).
  final bool includeUnverified;

  const EmbedProviderConfig({
    this.enabledProviders,
    this.providerRenderModes = const {},
    this.customProviders = const [],
    this.useDynamicDiscovery = false,
    this.includeUnverified = false,
  });

  @override
  List<Object?> get props => [
        enabledProviders,
        providerRenderModes,
        customProviders,
        useDynamicDiscovery,
        includeUnverified,
      ];

  /// Returns true if the given provider should be used.
  bool isEnabled(String providerName) {
    if (enabledProviders == null) return true;
    return enabledProviders!.contains(providerName);
  }

  /// Returns the render mode for the given provider. Defaults to
  /// [EmbedRenderMode.oembed] if not explicitly overridden.
  EmbedRenderMode getRenderMode(String providerName) {
    return providerRenderModes[providerName] ?? EmbedRenderMode.oembed;
  }

  /// Returns a copy of this configuration with the given fields replaced.
  EmbedProviderConfig copyWith({
    Set<String>? enabledProviders,
    Map<String, EmbedRenderMode>? providerRenderModes,
    List<EmbedProviderRule>? customProviders,
    bool? useDynamicDiscovery,
    bool? includeUnverified,
  }) {
    return EmbedProviderConfig(
      enabledProviders: enabledProviders ?? this.enabledProviders,
      providerRenderModes: providerRenderModes ?? this.providerRenderModes,
      customProviders: customProviders ?? this.customProviders,
      useDynamicDiscovery: useDynamicDiscovery ?? this.useDynamicDiscovery,
      includeUnverified: includeUnverified ?? this.includeUnverified,
    );
  }

  /// Returns the full merged provider list (built-in + custom) filtered by
  /// [enabledProviders].
  ///
  /// The result is memoized per instance via [_effectiveProvidersCache] to
  /// avoid re-allocating and re-filtering on every access. Since
  /// [EmbedProviderConfig] is immutable, the cached value never goes stale.
  ///
  /// Note: Dynamically discovered rules from [kEmbedProvidersSnapshot] are NOT
  /// included here for performance reasons. [EmbedService] handles efficient
  /// lookup in the snapshot separately.
  List<EmbedProviderRule> get effectiveProviders {
    final cached = _effectiveProvidersCache[this];
    if (cached != null) return cached;

    final all = <EmbedProviderRule>[
      ...customProviders,
      ...kDefaultEmbedProviders,
    ];

    final filtered = all.where((r) {
      if (includeUnverified) return true;
      if (customProviders.contains(r)) {
        return true;
      }
      return r.isVerified;
    }).toList();

    final result = enabledProviders == null
        ? filtered
        : filtered
            .where((r) => enabledProviders!.contains(r.providerName))
            .toList();

    _effectiveProvidersCache[this] = result;
    return result;
  }
}

/// Instance-level cache for [EmbedProviderConfig.effectiveProviders].
///
/// Uses [Expando] so the cached list is garbage-collected together with the
/// [EmbedProviderConfig] instance, and `const` constructability is preserved.
final Expando<List<EmbedProviderRule>> _effectiveProvidersCache = Expando();

/// Determines how embed content is rendered.
enum EmbedRenderMode {
  /// Fetch embed HTML via the OEmbed API and render it in a WebView.
  oembed,

  /// Build an iframe src URL directly (using [EmbedProviderRule.iframeUrlBuilder])
  /// and load it in a WebView, skipping the OEmbed API entirely.
  iframe,
}
