import 'package:flutter_oembed/src/core/provider_strategies.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/provider_rule.dart';
import 'package:flutter_oembed/src/utils/embed_link_utils.dart';

// ---------------------------------------------------------------------------
// Iframe URL builders
// ---------------------------------------------------------------------------

String? _buildYoutubeIframeUrl(String url) {
  return buildYoutubeEmbedUrl(url);
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
// Default provider registry
// ---------------------------------------------------------------------------

/// The built-in list of verified and commonly used OEmbed providers.
///
/// Rules are matched in order — put more-specific patterns before broader ones
/// of the same provider if needed. Providers with `isVerified: true` are
/// included by default; others require
/// [EmbedProviderConfig.includeUnverified].
const List<EmbedProviderRule> kDefaultEmbedProviders = [
  EmbedProviderRule(
    pattern:
        r'^https?:\/\/(?:www\.|m\.)?youtube(?:-nocookie)?\.com\/(?:watch|shorts|live|v|embed).*',
    endpoint: 'https://www.youtube.com/oembed',
    providerName: 'YouTube',
    strategy: YouTubeProviderStrategy(),
    iframeUrlBuilder: _buildYoutubeIframeUrl,
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'^https?:\/\/youtu\.be\/.*',
    endpoint: 'https://www.youtube.com/oembed',
    providerName: 'YouTube',
    strategy: YouTubeProviderStrategy(),
    iframeUrlBuilder: _buildYoutubeIframeUrl,
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?vimeo\.com\/.*',
    endpoint: 'https://vimeo.com/api/oembed.json',
    providerName: 'Vimeo',
    strategy: VimeoProviderStrategy(),
    iframeUrlBuilder: _buildVimeoIframeUrl,
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/open\.spotify\.com\/.*',
    endpoint: 'https://open.spotify.com/oembed',
    providerName: 'Spotify',
    strategy: SpotifyProviderStrategy(),
    iframeUrlBuilder: _buildSpotifyIframeUrl,
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?tiktok\.com\/.*',
    endpoint: 'https://www.tiktok.com/oembed',
    providerName: 'TikTok',
    strategy: TikTokProviderStrategy(),
    iframeUrlBuilder: _buildTikTokIframeUrl,
    shouldAllowNavigation: _tiktokNavigationCheck,
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?facebook\.com\/.*',
    endpoint: 'https://graph.facebook.com/v22.0/embed_post',
    providerName: 'Facebook',
    strategy: MetaProviderStrategy(EmbedType.facebook),
    shouldAllowNavigation: _facebookNavigationCheck,
    isVerified: true,
    subRules: [
      EmbedSubRule(
        pattern:
            r'^https?:\/\/(www\.)?facebook\.com\/(.*\/videos\/|video\.php\?id=|video\.php\?v=).*',
        endpoint: 'https://graph.facebook.com/v22.0/embed_video',
      ),
      EmbedSubRule(
        pattern: r'^https?:\/\/fb\.watch\/.*',
        endpoint: 'https://graph.facebook.com/v22.0/embed_video',
      ),
      EmbedSubRule(
        pattern:
            r'^https?:\/\/(www\.)?facebook\.com\/(.*\/posts\/|.*\/activity\/|.*\/photos\/|photo\.php\?fbid=|photos\/|permalink\.php\?story_fbid=|media\/set\?set=|questions\/|notes\/.*\/.*\/.*).*',
        endpoint: 'https://graph.facebook.com/v22.0/embed_post',
      ),
    ],
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?instagram\.com\/.*',
    endpoint: 'https://graph.facebook.com/v22.0/instagram_oembed',
    providerName: 'Instagram',
    strategy: MetaProviderStrategy(EmbedType.instagram),
    shouldAllowNavigation: _facebookNavigationCheck,
    isVerified: true,
    subRules: [
      EmbedSubRule(
        pattern:
            r'^https?:\/\/(www\.)?(instagram\.com|instagr\.am)\/(p|tv|reel|reels)\/.*',
        endpoint: 'https://graph.facebook.com/v22.0/instagram_oembed',
      ),
    ],
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?soundcloud\.com\/.*',
    endpoint: 'https://soundcloud.com/oembed',
    providerName: 'SoundCloud',
    strategy: SoundCloudProviderStrategy(),
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?threads\.net\/.*',
    endpoint: 'https://graph.threads.net/v1.0/oembed',
    providerName: 'Threads',
    strategy: MetaProviderStrategy(EmbedType.threads),
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?reddit\.com\/.*',
    endpoint: 'https://www.reddit.com/oembed',
    providerName: 'Reddit',
    strategy: RedditProviderStrategy(),
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(?:www\.|secure\.)?(?:flickr\.com|flic\.kr)\/.*',
    endpoint: 'https://www.flickr.com/services/oembed/?format=json',
    providerName: 'Flickr',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?ted\.com\/talks\/.*',
    endpoint: 'https://www.ted.com/services/v1/oembed.json',
    providerName: 'TED',
    isVerified: false,
  ),
  EmbedProviderRule(
    pattern:
        r'^https?:\/\/(?:[a-zA-Z0-9-]+\.)*tumblr\.com\/(?:post|blog\/view|[a-zA-Z0-9-]+\/\d+)(?:\/.*)?$',
    endpoint: 'https://www.tumblr.com/oembed/1.0',
    providerName: 'Tumblr',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?(twitter|x)\.com\/.*',
    endpoint: 'https://publish.twitter.com/oembed',
    providerName: 'X',
    strategy: XProviderStrategy(),
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?dailymotion\.com\/video\/.*',
    endpoint: 'https://www.dailymotion.com/services/oembed',
    providerName: 'Dailymotion',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/geo\.dailymotion\.com\/player\.html\?video=.*',
    endpoint: 'https://www.dailymotion.com/services/oembed',
    providerName: 'Dailymotion',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/(www\.)?giphy\.com\/(gifs|clips)\/.*',
    endpoint: 'https://giphy.com/services/oembed',
    providerName: 'Giphy',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/gph\.is\/.*',
    endpoint: 'https://giphy.com/services/oembed',
    providerName: 'Giphy',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'https?:\/\/media\.giphy\.com\/media\/.*\/giphy\.gif',
    endpoint: 'https://giphy.com/services/oembed',
    providerName: 'Giphy',
    isVerified: true,
  ),
  EmbedProviderRule(
    pattern: r'^https?:\/\/(?:www\.)?nytimes\.com\/.*',
    endpoint: 'https://www.nytimes.com/svc/oembed/json/',
    providerName: 'The New York Times',
    isVerified: true,
  ),
];
