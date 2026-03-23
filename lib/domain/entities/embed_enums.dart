// ignore_for_file: constant_identifier_names

enum EmbedType {
  x,
  tiktok,
  instagram,
  facebook_post,
  facebook_video,
  facebook,
  youtube
}

extension FBEmbedChecker on EmbedType {
  bool get isFacebook =>
      this == EmbedType.facebook ||
      this == EmbedType.facebook_post ||
      this == EmbedType.facebook_video;
}

enum EmbedButtonLocation {
  embed_bottom_link,
  embed_error,
  embed_body,
}

enum EmbedLoadingState { loading, noConnection, error, loaded }

enum EmbedContentType { newsReaderMode, richNewsStack, newsList }

EmbedType? getEmbedTypeFromString(String typeString) {
  final type = typeString.toLowerCase();

  switch (type) {
    case 'x':
    case 'twitter':
      return EmbedType.x;
    case 'tiktok':
      return EmbedType.tiktok;
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
  }

  return null;
}
