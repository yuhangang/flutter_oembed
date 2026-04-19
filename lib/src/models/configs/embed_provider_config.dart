import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/services/provider_registry.dart';

/// Utility helper for accessing built-in providers.
class EmbedProviders {
  /// All built-in providers, verified and unverified.
  static List<EmbedProviderRule> get all =>
      List<EmbedProviderRule>.unmodifiable(kDefaultEmbedProviders);

  /// Only built-in providers that are historically verified.
  static List<EmbedProviderRule> get verified =>
      List<EmbedProviderRule>.unmodifiable(
        kDefaultEmbedProviders.where((r) => r.isVerified),
      );
}

extension EmbedProvidersExtension on List<EmbedProviderRule> {
  /// Convenience method to clearly merge custom providers into an existing list.
  List<EmbedProviderRule> append(List<EmbedProviderRule> custom) {
    return [...this, ...custom];
  }
}

const Set<String> _defaultWebIframeProviders = {
  'YouTube',
  'Vimeo',
  'Spotify',
  'TikTok',
};

@visibleForTesting
EmbedRenderMode resolveEmbedRenderMode(
  String providerName, {
  required Map<String, EmbedRenderMode> overrides,
  bool isWeb = kIsWeb,
}) {
  final explicit = overrides[providerName];
  if (explicit != null) {
    return explicit;
  }

  if (isWeb && _defaultWebIframeProviders.contains(providerName)) {
    return EmbedRenderMode.iframe;
  }

  return EmbedRenderMode.oembed;
}

/// Controls which OEmbed providers are active and how they render content.
class EmbedProviderConfig extends Equatable {
  /// The explicit list of provider rules used to match URLs.
  ///
  /// If `null`, it dynamically defaults to [EmbedProviders.verified] when matched.
  final List<EmbedProviderRule>? providers;

  /// Per-provider render mode overrides.
  ///
  /// When a provider is mapped to [EmbedRenderMode.iframe], the library will
  /// use the provider's [EmbedProviderRule.iframeUrlBuilder] to construct an
  /// iframe src URL directly, skipping the OEmbed API call entirely.
  final Map<String, EmbedRenderMode> providerRenderModes;

  const EmbedProviderConfig({
    this.providers,
    this.providerRenderModes = const {},
  });

  @override
  List<Object?> get props => [
        providers,
        providerRenderModes,
      ];

  /// Returns true if the given provider is available in the current active list.
  bool isEnabled(String providerName) {
    final activeList = providers ?? EmbedProviders.verified;
    return activeList.any((r) => r.providerName == providerName);
  }

  /// Returns the render mode for the given provider. Defaults to
  /// [EmbedRenderMode.oembed] if not explicitly overridden.
  ///
  /// On Flutter Web, iframe-capable providers default to
  /// [EmbedRenderMode.iframe] to avoid browser-side CORS failures when their
  /// oEmbed endpoints do not allow direct fetches from the app origin.
  EmbedRenderMode getRenderMode(String providerName) {
    return resolveEmbedRenderMode(
      providerName,
      overrides: providerRenderModes,
    );
  }

  /// Returns a copy of this configuration with the given fields replaced.
  EmbedProviderConfig copyWith({
    Object? providers = _copyWithSentinel,
    Map<String, EmbedRenderMode>? providerRenderModes,
  }) {
    return EmbedProviderConfig(
      providers: identical(providers, _copyWithSentinel)
          ? this.providers
          : providers as List<EmbedProviderRule>?,
      providerRenderModes: providerRenderModes ?? this.providerRenderModes,
    );
  }

  /// Memoized rule lookup for repeated resolutions against the same config.
  EmbedProviderRule? matchRule(String url) {
    final cache = _matchedRuleCache[this] ??= <String, Object?>{};
    if (cache.containsKey(url)) {
      final cached = cache[url];
      return identical(cached, _noMatchedRuleSentinel)
          ? null
          : cached as EmbedProviderRule;
    }

    EmbedProviderRule? result;
    final activeList = providers ?? EmbedProviders.verified;
    for (final rule in activeList) {
      if (rule.matches(url)) {
        result = rule;
        break;
      }
    }

    cache[url] = result ?? _noMatchedRuleSentinel;
    return result;
  }
}

final Expando<Map<String, Object?>> _matchedRuleCache = Expando();
final Object _noMatchedRuleSentinel = Object();
const Object _copyWithSentinel = Object();

/// Determines how embed content is rendered.
enum EmbedRenderMode {
  /// Fetch embed HTML via the OEmbed API and render it in a WebView.
  oembed,

  /// Build an iframe src URL directly (using [EmbedProviderRule.iframeUrlBuilder])
  /// and load it in a WebView, skipping the OEmbed API entirely.
  iframe,
}
