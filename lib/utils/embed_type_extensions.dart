import 'package:oembed/domain/entities/embed_enums.dart';

extension EmbedTypeExtension on EmbedType {
  String get svgIconUrl {
    switch (this) {
      case EmbedType.x:
        return 'assets/icons/embed_icon_x.svg';
      case EmbedType.tiktok:
        return 'assets/icons/embed_icon_tiktok.svg';
      case EmbedType.instagram:
        return 'assets/icons/embed_icon_instagram.svg';
      case EmbedType.facebook:
      case EmbedType.facebook_post:
      case EmbedType.facebook_video:
        return 'assets/icons/embed_icon_facebook.svg';
      default:
        return '';
    }
  }

  String get displayName {
    switch (this) {
      case EmbedType.x:
        return 'X';
      case EmbedType.tiktok:
        return 'TikTok';
      case EmbedType.instagram:
        return 'Instagram';
      case EmbedType.facebook:
      case EmbedType.facebook_post:
      case EmbedType.facebook_video:
        return 'Facebook';
      case EmbedType.youtube:
        return 'YouTube';
    }
  }

  bool get isMeta {
    switch (this) {
      case EmbedType.facebook:
      case EmbedType.facebook_post:
      case EmbedType.facebook_video:
      case EmbedType.instagram:
        return true;
      default:
        return false;
    }
  }
}
