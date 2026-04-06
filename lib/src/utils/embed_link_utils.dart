const String kTikTokV3EmbedUrl = 'https://www.tiktok.com/embed/v3';
const String kYouTubeEmbedBaseUrl = 'https://www.youtube.com/embed';

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

final _youtubeWatchRegex =
    RegExp(r'^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/watch.*');
final _youtubeIdRegexes = [
  RegExp(
      r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$"),
  RegExp(
      r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/embed\/([_\-a-zA-Z0-9]{11}).*$"),
  RegExp(
      r"^https:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/(?:shorts|live|v)\/([_\-a-zA-Z0-9]{11}).*$"),
  RegExp(r"^https:\/\/youtu\.be\/([_\-a-zA-Z0-9]{11}).*$")
];

String getYoutubeEmbedParam(String url) {
  if (_youtubeWatchRegex.hasMatch(url)) {
    return url;
  } else {
    final youtubeId = getYoutubeVideoId(url);
    if (youtubeId != null) {
      return 'https://www.youtube.com/watch?v=$youtubeId';
    }
    return url; // fallback
  }
}

String? getYoutubeVideoId(String url, {bool trimWhitespaces = true}) {
  if (!url.contains("http") && (url.length == 11)) return url;
  if (trimWhitespaces) url = url.trim();

  for (var exp in _youtubeIdRegexes) {
    Match? match = exp.firstMatch(url);
    if (match != null && match.groupCount >= 1) return match.group(1);
  }

  return null;
}

String? buildYoutubeEmbedUrl(
  String urlOrId, {
  Map<String, String>? queryParameters,
}) {
  final videoId = getYoutubeVideoId(urlOrId);
  if (videoId == null || videoId.isEmpty) return null;
  return Uri.parse('$kYouTubeEmbedBaseUrl/$videoId')
      .replace(queryParameters: queryParameters)
      .toString();
}
