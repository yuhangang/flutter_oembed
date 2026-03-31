import 'package:collection/collection.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/services/provider_registry.dart';

/// A utility class to match URLs against known [EmbedType]s.
class EmbedMatchers {
  /// Resolves the [EmbedType] for a given [url] by matching it against 
  /// the default OEmbed provider rules.
  static EmbedType getEmbedType(String url) {
    // First, try to match against kDefaultEmbedProviders
    final rule = kDefaultEmbedProviders.firstWhereOrNull(
      (element) => element.matches(url),
    );

    if (rule != null) {
      return fromProviderName(rule.providerName, url: url);
    }

    return EmbedType.other;
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

    if (n == 'facebook') {
      if (url != null) {
        final uri = url.toLowerCase();
        if (uri.contains('/videos/') || uri.contains('video.php') || uri.contains('fb.watch')) {
          return EmbedType.facebook_video;
        }
        if (uri.contains('/posts/') || uri.contains('permalink.php') || uri.contains('photo.php')) {
          return EmbedType.facebook_post;
        }
      }
      return EmbedType.facebook;
    }

    return EmbedType.other;
  }
}
