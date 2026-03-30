import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/provider_rule.dart';
import 'package:oembed/src/services/api/base_oembed_api.dart';
import 'package:oembed/src/services/api/meta_embed_api.dart';
import 'package:oembed/src/services/api/spotify_embed_api.dart';
import 'package:oembed/src/services/api/tiktok_embed_api.dart';
import 'package:oembed/src/services/api/vimeo_embed_api.dart';
import 'package:oembed/src/services/api/x_embed_api.dart';
import 'package:oembed/src/utils/embed_matchers.dart';
import 'package:oembed/src/services/api/reddit_embed_api.dart';

// ---------------------------------------------------------------------------
// Iframe URL builders
// ---------------------------------------------------------------------------

String? _buildYoutubeIframeUrl(String url) {
  final patterns = [
    RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'/embed/([a-zA-Z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(url);
    if (m != null) return 'https://www.youtube.com/embed/${m.group(1)}';
  }
  return null;
}

String? _buildVimeoIframeUrl(String url) {
  final m = RegExp(r'vimeo\.com/(?:video/)?(\d+)').firstMatch(url);
  if (m != null) return 'https://player.vimeo.com/video/${m.group(1)}';
  return null;
}

String? _buildSpotifyIframeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  if (segments.length >= 2) {
    return 'https://open.spotify.com/embed/${segments.join('/')}';
  }
  return null;
}

BaseOembedApi _redditApiFactory(OembedProviderContext ctx) =>
    RedditEmbedApi(width: ctx.width);

String? _buildTikTokIframeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final id = uri.pathSegments.lastWhere(
    (s) => int.tryParse(s) != null,
    orElse: () => '',
  );
  if (id.isEmpty) return null;
  return 'https://www.tiktok.com/embed/v3/$id';
}

// ---------------------------------------------------------------------------
// Navigation check helpers
// ---------------------------------------------------------------------------

bool _tiktokNavigationCheck(String url) =>
    url.contains('https://www.tiktok.com/embed/v3/');

bool _facebookNavigationCheck(String url) {
  final uri = Uri.tryParse(url);
  return uri?.pathSegments.contains('plugins') ?? false;
}

// ---------------------------------------------------------------------------
// API factory functions
// ---------------------------------------------------------------------------

BaseOembedApi _vimeoApiFactory(OembedProviderContext ctx) =>
    VimeoEmbedApi(ctx.width);
BaseOembedApi _spotifyApiFactory(OembedProviderContext ctx) =>
    const SpotifyEmbedApi();
BaseOembedApi _tiktokApiFactory(OembedProviderContext ctx) =>
    const TikTokEmbedApi();
BaseOembedApi _xApiFactory(OembedProviderContext ctx) => const XEmbedApi();

BaseOembedApi _facebookApiFactory(OembedProviderContext ctx) {
  return MetaEmbedApi(
    EmbedMatchers.fromProviderName('Facebook', url: ctx.url),
    ctx.width,
    ctx.facebookAppId,
    ctx.facebookClientToken,
    endpoint: ctx.resolvedEndpoint,
    proxyUrl: ctx.proxyUrl,
  );
}

BaseOembedApi _instagramApiFactory(OembedProviderContext ctx) {
  return MetaEmbedApi(
    EmbedType.instagram,
    ctx.width,
    ctx.facebookAppId,
    ctx.facebookClientToken,
    endpoint: ctx.resolvedEndpoint,
    proxyUrl: ctx.proxyUrl,
  );
}

// ---------------------------------------------------------------------------
// Default provider registry
// ---------------------------------------------------------------------------

/// The built-in list of verified and commonly used OEmbed providers.
///
/// Rules are matched in order — put more-specific patterns before broader ones
/// of the same provider if needed. Providers with `isVerified: true` are
/// included by default; others require
/// [OembedProviderConfig.includeUnverified].
final List<OembedProviderRule> kDefaultOembedProviders = [
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?youtube\.com\/watch.*',
    endpoint: 'https://www.youtube.com/oembed',
    providerName: 'YouTube',
    iframeUrlBuilder: _buildYoutubeIframeUrl,
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/youtu\.be\/.*',
    endpoint: 'https://www.youtube.com/oembed',
    providerName: 'YouTube',
    iframeUrlBuilder: _buildYoutubeIframeUrl,
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?vimeo\.com\/.*',
    endpoint: 'https://vimeo.com/api/oembed.json',
    providerName: 'Vimeo',
    iframeUrlBuilder: _buildVimeoIframeUrl,
    apiFactory: _vimeoApiFactory,
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/open\.spotify\.com\/.*',
    endpoint: 'https://open.spotify.com/oembed',
    providerName: 'Spotify',
    iframeUrlBuilder: _buildSpotifyIframeUrl,
    apiFactory: _spotifyApiFactory,
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?tiktok\.com\/.*',
    endpoint: 'https://www.tiktok.com/oembed',
    providerName: 'TikTok',
    iframeUrlBuilder: _buildTikTokIframeUrl,
    shouldAllowNavigation: _tiktokNavigationCheck,
    apiFactory: _tiktokApiFactory,
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?facebook\.com\/.*',
    endpoint: 'https://graph.facebook.com/v22.0/oembed_post',
    providerName: 'Facebook',
    shouldAllowNavigation: _facebookNavigationCheck,
    apiFactory: _facebookApiFactory,
    isVerified: true,
    subRules: [
      OembedSubRule(
        pattern:
            r'^https?:\/\/(www\.)?facebook\.com\/(.*\/videos\/|video\.php\?id=|video\.php\?v=).*',
        endpoint: 'https://graph.facebook.com/v22.0/oembed_video',
      ),
      OembedSubRule(
        pattern: r'^https?:\/\/fb\.watch\/.*',
        endpoint: 'https://graph.facebook.com/v22.0/oembed_video',
      ),
      OembedSubRule(
        pattern:
            r'^https?:\/\/(www\.)?facebook\.com\/(.*\/posts\/|.*\/activity\/|.*\/photos\/|photo\.php\?fbid=|photos\/|permalink\.php\?story_fbid=|media\/set\?set=|questions\/|notes\/.*\/.*\/.*).*',
        endpoint: 'https://graph.facebook.com/v22.0/oembed_post',
      ),
    ],
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?instagram\.com\/.*',
    endpoint: 'https://graph.facebook.com/v22.0/instagram_oembed',
    providerName: 'Instagram',
    shouldAllowNavigation: _facebookNavigationCheck,
    apiFactory: _instagramApiFactory,
    isVerified: true,
    subRules: [
      OembedSubRule(
        pattern:
            r'^https?:\/\/(www\.)?(instagram\.com|instagr\.am)\/(p|tv|reel|reels)\/.*',
        endpoint: 'https://graph.facebook.com/v22.0/instagram_oembed',
      ),
    ],
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?soundcloud\.com\/.*',
    endpoint: 'https://soundcloud.com/oembed',
    providerName: 'SoundCloud',
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?threads\.net\/.*',
    endpoint: 'https://graph.threads.net/v1.0/oembed',
    providerName: 'Threads',
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?reddit\.com\/.*',
    endpoint: 'https://www.reddit.com/oembed',
    providerName: 'Reddit',
    isVerified: true,
    apiFactory: _redditApiFactory,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?flickr\.com\/.*',
    endpoint: 'https://www.flickr.com/services/oembed/',
    providerName: 'Flickr',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?ted\.com\/talks\/.*',
    endpoint: 'https://www.ted.com/services/v1/oembed.json',
    providerName: 'TED',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?tumblr\.com\/.*',
    endpoint: 'https://www.tumblr.com/oembed/1.0',
    providerName: 'Tumblr',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?imgur\.com\/.*',
    endpoint: 'https://api.imgur.com/oembed',
    providerName: 'Imgur',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?mixcloud\.com\/.*',
    endpoint: 'https://app.mixcloud.com/oembed/',
    providerName: 'Mixcloud',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?kickstarter\.com\/.*',
    endpoint: 'https://www.kickstarter.com/services/oembed',
    providerName: 'Kickstarter',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/pca\.st\/.*',
    endpoint: 'https://pca.st/oembed.json',
    providerName: 'Pocket Casts',
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?(twitter|x)\.com\/.*',
    endpoint: 'https://publish.twitter.com/oembed',
    providerName: 'X',
    apiFactory: _xApiFactory,
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/(www\.)?dailymotion\.com\/video\/.*',
    endpoint: 'https://www.dailymotion.com/services/oembed',
    providerName: 'Dailymotion',
    isVerified: true,
  ),
  const OembedProviderRule(
    pattern: r'https?:\/\/geo\.dailymotion\.com\/player\.html\?video=.*',
    endpoint: 'https://www.dailymotion.com/services/oembed',
    providerName: 'Dailymotion',
    isVerified: true,
  ),
];
