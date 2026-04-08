import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_provider_config.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderRegistry Iframe Builders', () {
    const config = EmbedConfig(
      providers: EmbedProviderConfig(
        providerRenderModes: {
          'YouTube': EmbedRenderMode.iframe,
          'Vimeo': EmbedRenderMode.iframe,
          'Spotify': EmbedRenderMode.iframe,
          'TikTok': EmbedRenderMode.iframe,
        },
      ),
    );

    test('should return the correct iframe URL for YouTube', () {
      final url = EmbedService.resolveIframeUrl(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          config: config);
      expect(url, contains('youtube.com/embed/dQw4w9WgXcQ'));
    });

    test('should return the correct iframe URL for Vimeo', () {
      final url = EmbedService.resolveIframeUrl('https://vimeo.com/12345',
          config: config);
      expect(url, equals('https://player.vimeo.com/video/12345'));
    });

    test('should return the correct iframe URL for Spotify', () {
      final url = EmbedService.resolveIframeUrl(
          'https://open.spotify.com/track/123',
          config: config);
      expect(url, equals('https://open.spotify.com/embed/track/123'));
    });

    test('should return the correct iframe URL for TikTok', () {
      final url = EmbedService.resolveIframeUrl(
          'https://www.tiktok.com/@user/video/123',
          config: config);
      expect(url, equals('https://www.tiktok.com/embed/v3/123'));
    });
  });

  group('ProviderRegistry Navigation Checks', () {
    test('should correctly identify allowed navigation for TikTok embeds', () {
      final rule =
          EmbedService.resolveRule('https://www.tiktok.com/@user/video/123');
      expect(
          rule?.shouldAllowNavigation
              ?.call('https://www.tiktok.com/embed/v3/123'),
          isTrue);
      expect(rule?.shouldAllowNavigation?.call('https://google.com'), isFalse);
    });

    test('should correctly identify allowed navigation for Facebook embeds',
        () {
      final rule = EmbedService.resolveRule('https://www.facebook.com/post/1');
      expect(
          rule?.shouldAllowNavigation
              ?.call('https://www.facebook.com/plugins/post.php'),
          isTrue);
      expect(
          rule?.shouldAllowNavigation
              ?.call('https://www.facebook.com/plugins/video.php'),
          isTrue);
      expect(
          rule?.shouldAllowNavigation?.call('https://www.facebook.com/other'),
          isFalse);
    });
  });
}
