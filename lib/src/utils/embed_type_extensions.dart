import 'package:flutter_oembed/src/models/embed_enums.dart';

extension EmbedTypeExtension on EmbedType {
  String get displayName {
    switch (this) {
      case EmbedType.x:
        return 'X';
      case EmbedType.tiktok:
      case EmbedType.tiktok_v1:
        return 'TikTok';
      case EmbedType.instagram:
        return 'Instagram';
      case EmbedType.facebook:
      case EmbedType.facebook_post:
      case EmbedType.facebook_video:
        return 'Facebook';
      case EmbedType.youtube:
        return 'YouTube';
      case EmbedType.spotify:
        return 'Spotify';
      case EmbedType.vimeo:
        return 'Vimeo';
      case EmbedType.other:
        return 'Other';
      case EmbedType.dailymotion:
        return 'Dailymotion';
      case EmbedType.soundcloud:
        return 'SoundCloud';
      case EmbedType.threads:
        return 'Threads';
      case EmbedType.reddit:
        return 'Reddit';
      case EmbedType.giphy:
        return 'GIPHY';
      case EmbedType.nytimes:
        return 'NYTimes';
    }
  }

  bool get isMeta {
    switch (this) {
      case EmbedType.facebook:
      case EmbedType.facebook_post:
      case EmbedType.facebook_video:
      case EmbedType.instagram:
      case EmbedType.threads:
        return true;
      default:
        return false;
    }
  }
}
