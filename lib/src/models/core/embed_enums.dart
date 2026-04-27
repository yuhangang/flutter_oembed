// ignore_for_file: constant_identifier_names

enum EmbedType {
  x,
  tiktok,
  instagram,
  facebook_post,
  facebook_video,
  facebook,
  youtube,
  spotify,
  vimeo,
  dailymotion,
  soundcloud,
  threads,
  reddit,
  giphy,
  tiktok_v1,
  codepen,
  other,
}

extension EmbedTypeChecks on EmbedType {
  bool get isFacebook =>
      this == EmbedType.facebook ||
      this == EmbedType.facebook_post ||
      this == EmbedType.facebook_video;

  bool get isTikTok => this == EmbedType.tiktok || this == EmbedType.tiktok_v1;

  bool get isVideo =>
      this == EmbedType.youtube ||
      this == EmbedType.vimeo ||
      this == EmbedType.tiktok ||
      this == EmbedType.tiktok_v1 ||
      this == EmbedType.dailymotion ||
      this == EmbedType.facebook_video;
}

enum EmbedLoadingState { loading, noConnection, error, loaded }

EmbedType? getEmbedTypeFromString(String typeString) {
  final type = typeString.toLowerCase();

  switch (type) {
    case 'x':
    case 'twitter':
      return EmbedType.x;
    case 'tiktok':
      return EmbedType.tiktok;
    case 'tiktok_v1':
      return EmbedType.tiktok_v1;
    case 'instagram':
      return EmbedType.instagram;
    case 'facebook':
      return EmbedType.facebook;
    case 'facebook_post':
      return EmbedType.facebook_post;
    case 'facebook_video':
      return EmbedType.facebook_video;
    case 'youtube':
      return EmbedType.youtube;
    case 'spotify':
      return EmbedType.spotify;
    case 'vimeo':
      return EmbedType.vimeo;
    case 'dailymotion':
      return EmbedType.dailymotion;
    case 'soundcloud':
      return EmbedType.soundcloud;
    case 'threads':
      return EmbedType.threads;
    case 'reddit':
      return EmbedType.reddit;
    case 'giphy':
      return EmbedType.giphy;
    case 'codepen':
      return EmbedType.codepen;
  }

  return null;
}
