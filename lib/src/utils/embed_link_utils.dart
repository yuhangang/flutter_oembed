const String kTikTokV3EmbedUrl = 'https://www.tiktok.com/embed/v3';
const String kYouTubeEmbedBaseUrl = 'https://www.youtube.com/embed';
const String kSpotifyEmbedBaseUrl = 'https://open.spotify.com/embed';
const String kVimeoEmbedBaseUrl = 'https://player.vimeo.com/video';

// ---------------------------------------------------------------------------
// TikTok Utilities
// ---------------------------------------------------------------------------

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
  final embedUri = Uri.parse('$kYouTubeEmbedBaseUrl/$videoId');
  final mergedQueryParameters = <String, String>{
    'playsinline': '1',
    'enablejsapi': '1',
    'origin': embedUri.origin,
    'widget_referrer': embedUri.origin,
    if (queryParameters != null) ...queryParameters,
  };

  return embedUri.replace(queryParameters: mergedQueryParameters).toString();
}

// ---------------------------------------------------------------------------
// Spotify Utilities
// ---------------------------------------------------------------------------

final _spotifyRegex = RegExp(
  r'open\.spotify\.com\/(track|album|playlist|artist|show|episode)\/([a-zA-Z0-9]+)',
);

/// Extracts the Spotify type and ID from a URL.
/// Returns a [Record] with (type, id) or null.
(String type, String id)? getSpotifyMetadata(String url) {
  final match = _spotifyRegex.firstMatch(url);
  if (match != null && match.groupCount >= 2) {
    return (match.group(1)!, match.group(2)!);
  }
  return null;
}

/// Builds a Spotify iframe URL from a content URL.
String? buildSpotifyEmbedUrl(String url) {
  final meta = getSpotifyMetadata(url);
  if (meta == null) return null;
  return '$kSpotifyEmbedBaseUrl/${meta.$1}/${meta.$2}';
}

// ---------------------------------------------------------------------------
// Vimeo Utilities
// ---------------------------------------------------------------------------

final _vimeoRegex = RegExp(
  r'vimeo\.com\/(?:channels\/[^\/]+\/|groups\/[^\/]+\/videos\/|video\/|)?(\d+)',
);

/// Extracts the Vimeo video ID from a URL.
String? getVimeoVideoId(String url) {
  final match = _vimeoRegex.firstMatch(url);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }
  return null;
}

/// Builds a Vimeo iframe URL from a content URL.
String? buildVimeoEmbedUrl(String url) {
  final videoId = getVimeoVideoId(url);
  if (videoId == null) return null;
  return '$kVimeoEmbedBaseUrl/$videoId';
}
