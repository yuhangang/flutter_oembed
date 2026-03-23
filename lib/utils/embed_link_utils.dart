const String kTikTokV3EmbedUrl = 'https://www.tiktok.com/embed/v3';

String? getTikTokEmbedUrl(String url) {
  final Uri uri = Uri.parse(url);

  bool isTikTokVideo = uri.host.contains('tiktok') &&
      (uri.pathSegments.contains('video') ||
          uri.pathSegments.contains('photo') ||
          uri.pathSegments.contains('v') ||
          uri.pathSegments.contains('embed')) &&
      int.tryParse(uri.pathSegments.last) != null;

  if (isTikTokVideo) {
    return '$kTikTokV3EmbedUrl/${uri.pathSegments.last}';
  } else {
    return null;
  }
}

String getYoutubeEmbedParam(String url) {
  if (RegExp(r'^https://(?:www\.|m\.)?youtube\.com/watch.*').hasMatch(url)) {
    return url;
  } else {
    final youtubeId = _convertUrlToId(url);
    if (youtubeId != null) {
      return 'https://www.youtube.com/watch?v=$youtubeId';
    }
    return url; // fallback
  }
}

String? _convertUrlToId(String url, {bool trimWhitespaces = true}) {
  if (!url.contains("http") && (url.length == 11)) return url;
  if (trimWhitespaces) url = url.trim();

  for (var exp in [
    RegExp(r"^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
    RegExp(r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
    RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
  ]) {
    Match? match = exp.firstMatch(url);
    if (match != null && match.groupCount >= 1) return match.group(1);
  }

  return null;
}
