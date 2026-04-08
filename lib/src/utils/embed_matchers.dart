import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/services/embed_service.dart';

/// A utility class to match URLs against known [EmbedType]s.
class EmbedMatchers {
  /// Resolves the [EmbedType] for a given [url].
  ///
  /// Delegates to [EmbedService.resolveRule] so that custom providers
  /// registered via [EmbedConfig.providers] are also considered. Falls back to
  /// [EmbedType.other] when no rule matches.
  ///
  /// Provide [config] to include custom providers. When [config] is null,
  /// only the built-in [kDefaultEmbedProviders] are checked — which matches the
  /// original behaviour for contexts where [EmbedConfig] is not yet available
  /// (e.g. construction of [SocialEmbedParam] before a [BuildContext] exists).
  static EmbedType getEmbedType(String url, {EmbedConfig? config}) {
    final rule = EmbedService.resolveRule(url, config: config);
    if (rule == null) return EmbedType.other;
    return fromProviderName(rule.providerName, url: url);
  }

  /// Maps a provider name string to an [EmbedType].
  ///
  /// Optionally takes the [url] to distinguish between sub-types
  /// (e.g., Facebook Post vs Video).
  static EmbedType fromProviderName(String name, {String? url}) {
    final n = name.toLowerCase();

    if (n == 'youtube') return EmbedType.youtube;
    if (n == 'x' || n == 'twitter') return EmbedType.x;
    if (n == 'instagram') return EmbedType.instagram;
    if (n == 'tiktok') return EmbedType.tiktok;
    if (n == 'spotify') return EmbedType.spotify;
    if (n == 'vimeo') return EmbedType.vimeo;
    if (n == 'dailymotion') return EmbedType.dailymotion;
    if (n == 'soundcloud') return EmbedType.soundcloud;
    if (n == 'threads') return EmbedType.threads;
    if (n == 'reddit') return EmbedType.reddit;
    if (n == 'giphy') return EmbedType.giphy;

    if (n == 'facebook') {
      if (url != null) {
        final uri = url.toLowerCase();
        if (uri.contains('/videos/') ||
            uri.contains('video.php') ||
            uri.contains('fb.watch')) {
          return EmbedType.facebook_video;
        }
        if (uri.contains('/posts/') ||
            uri.contains('permalink.php') ||
            uri.contains('photo.php')) {
          return EmbedType.facebook_post;
        }
      }
      return EmbedType.facebook;
    }

    return EmbedType.other;
  }
}
