const int kPreloadEmbedCount = 1;
const int kLazyLoadEmbedCount = 5;
const Duration kDefaultEmbedHtmlCacheLifeSpan = Duration(days: 7);
const Duration kLoadEmbedPostTimeout = Duration(seconds: 25);
const Duration kCalculateEmbedPostHeightDelay = Duration(milliseconds: 500);
const Duration kCalculateFacebookEmbedPostHeightDelay =
    Duration(milliseconds: 1500);

class EmbedClasses {
  // social embed
  static const String embedYt = 'embed-yt';
  static const String embedTwitter = 'embed-twitter';
  static const String embedX = 'embed-x';
  static const String embedIg = 'embed-ig';
  static const String embedTiktok = 'embed-tiktok';
  static const String embedFbPost = 'embed-fb-post';
  static const String embedFbVideo = 'embed-fb-video';

  // RNS / custom tab
  static const String searchPill = 'search-pill';
  static const String anchorLink = 'anchor-link';
}
