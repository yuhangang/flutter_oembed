/// Extension to help identify video-based URLs for example styling.
extension VideoUrlChecker on String {
  bool get isLikelyVideoUrl {
    final url = toLowerCase();
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com') ||
        url.contains('tiktok.com') ||
        url.contains('dailymotion.com') ||
        url.contains('dai.ly');
  }
}
