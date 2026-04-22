import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/services/provider_registry.dart';

void main() {
  group('kDefaultEmbedProviders', () {
    test('YouTube pattern matches standard watch URLs', () {
      final youtubeRules = kDefaultEmbedProviders.where(
        (r) => r.providerName == 'YouTube',
      );
      expect(
        youtubeRules.any(
            (r) => r.matches('https://www.youtube.com/watch?v=dQw4w9WgXcQ')),
        isTrue,
      );
      expect(
        youtubeRules.any((r) => r.matches('https://youtu.be/dQw4w9WgXcQ')),
        isTrue,
      );
      expect(
        youtubeRules.any((r) => r.matches('https://vimeo.com/123456')),
        isFalse,
      );
    });

    test('Tumblr pattern matches with protocol and optional www', () {
      final tumblrRules = kDefaultEmbedProviders.where(
        (r) => r.providerName == 'Tumblr',
      );
      expect(
        tumblrRules.any((r) => r.matches('https://www.tumblr.com/post/1')),
        isTrue,
      );
      expect(
        tumblrRules.any((r) => r.matches('http://tumblr.com/post/1')),
        isTrue,
      );
    });

    test('TikTok iframeUrlBuilder returns v3 embed URL for videos', () {
      final tiktok = kDefaultEmbedProviders.firstWhere(
        (r) => r.providerName == 'TikTok',
      );
      final result = tiktok.iframeUrlBuilder!(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      expect(result, 'https://www.tiktok.com/embed/v3/6718335390845095173');
    });

    test('YouTube iframeUrlBuilder extracts video ID correctly', () {
      final yt = kDefaultEmbedProviders.firstWhere(
        (r) => r.providerName == 'YouTube',
      );
      final result = yt.iframeUrlBuilder!(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(
        result,
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1&enablejsapi=1&origin=https%3A%2F%2Fwww.youtube-nocookie.com&widget_referrer=https%3A%2F%2Fwww.youtube-nocookie.com',
      );
    });

    test('Vimeo iframeUrlBuilder extracts video ID', () {
      final vimeo = kDefaultEmbedProviders.firstWhere(
        (r) => r.providerName == 'Vimeo',
      );
      final result = vimeo.iframeUrlBuilder!('https://vimeo.com/22439234');
      expect(result, 'https://player.vimeo.com/video/22439234?api=1');
    });

    test('Spotify iframeUrlBuilder builds correct embed URL', () {
      final spotify = kDefaultEmbedProviders.firstWhere(
        (r) => r.providerName == 'Spotify',
      );
      final result = spotify.iframeUrlBuilder!(
        'https://open.spotify.com/track/4cOdK2wGvV9m9X7S7O0WhS',
      );
      expect(result, contains('open.spotify.com/embed'));
    });

    test('Facebook sub-rules resolve video endpoint for video URLs', () {
      final fb = kDefaultEmbedProviders.firstWhere(
        (r) => r.providerName == 'Facebook',
      );
      final endpoint = fb.resolveEndpoint(
        'https://www.facebook.com/user/videos/123456',
      );
      expect(endpoint, contains('embed_video'));
    });

    test('Facebook sub-rules resolve post endpoint for post URLs', () {
      final fb = kDefaultEmbedProviders.firstWhere(
        (r) => r.providerName == 'Facebook',
      );
      final endpoint = fb.resolveEndpoint(
        'https://www.facebook.com/user/posts/123456',
      );
      expect(endpoint, contains('embed_post'));
    });

    test('EmbedProviderRule.matches uses cached regex correctly', () {
      final rule = const EmbedProviderRule(
        pattern: r'https?:\/\/(www\.)?example\.com\/.*',
        endpoint: 'https://example.com/oembed',
        providerName: 'Example',
      );
      expect(rule.matches('https://www.example.com/page'), isTrue);
      expect(rule.matches('https://other.com/page'), isFalse);
      // Call twice to ensure cached path works
      expect(rule.matches('https://www.example.com/page'), isTrue);
    });
  });
}
