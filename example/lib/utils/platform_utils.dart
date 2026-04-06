import 'package:flutter_embed/flutter_embed.dart';

/// Platform logo asset mapping
String? getPlatformAsset(EmbedType type) {
  switch (type) {
    case EmbedType.youtube:
      return 'assets/logos/youtube.svg';
    case EmbedType.facebook:
    case EmbedType.facebook_post:
    case EmbedType.facebook_video:
      return 'assets/logos/facebook.svg';
    case EmbedType.instagram:
      return 'assets/logos/instagram.svg';
    case EmbedType.tiktok:
    case EmbedType.tiktok_v1:
      return 'assets/logos/tiktok.svg';
    case EmbedType.x:
      return 'assets/logos/x.svg';
    case EmbedType.spotify:
      return 'assets/logos/spotify.svg';
    case EmbedType.vimeo:
      return 'assets/logos/vimeo.svg';
    case EmbedType.dailymotion:
      return 'assets/logos/dailymotion.svg';
    case EmbedType.soundcloud:
      return 'assets/logos/soundcloud.svg';
    case EmbedType.threads:
      return 'assets/logos/threads.svg';
    case EmbedType.reddit:
      return 'assets/logos/reddit.svg';
    case EmbedType.giphy:
      return 'assets/logos/giphy.png';
    default:
      return null;
  }
}

/// Helper to get EmbedType from URL in the example app
EmbedType? getEmbedTypeFromUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  if (host.contains('youtube.com') || host.contains('youtu.be')) {
    return EmbedType.youtube;
  }
  if (host.contains('twitter.com') || host.contains('x.com')) {
    return EmbedType.x;
  }
  if (host.contains('instagram.com')) return EmbedType.instagram;
  if (host.contains('tiktok.com')) return EmbedType.tiktok;
  if (host.contains('facebook.com')) return EmbedType.facebook;
  if (host.contains('spotify.com')) return EmbedType.spotify;
  if (host.contains('vimeo.com')) return EmbedType.vimeo;
  if (host.contains('dailymotion.com')) return EmbedType.dailymotion;
  if (host.contains('soundcloud.com')) return EmbedType.soundcloud;
  if (host.contains('threads.net')) return EmbedType.threads;
  if (host.contains('reddit.com')) return EmbedType.reddit;
  if (host.contains('giphy.com')) return EmbedType.giphy;

  return null;
}
