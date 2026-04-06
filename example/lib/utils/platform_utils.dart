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
    default:
      return null;
  }
}
