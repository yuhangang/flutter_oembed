import 'package:flutter_oembed/src/utils/embed_link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedLinkUtils', () {
    test('getTikTokEmbedUrl matches various patterns', () {
      expect(getTikTokEmbedUrl('https://www.tiktok.com/@user/video/123'),
          equals('https://www.tiktok.com/embed/v3/123'));
      expect(getTikTokEmbedUrl('https://www.tiktok.com/@user/photo/456'),
          equals('https://www.tiktok.com/embed/v3/456'));
      expect(getTikTokEmbedUrl('https://www.tiktok.com/v/789'),
          equals('https://www.tiktok.com/embed/v3/789'));
      expect(getTikTokEmbedUrl('https://www.tiktok.com/embed/101'),
          equals('https://www.tiktok.com/embed/v3/101'));
      expect(getTikTokEmbedUrl('https://example.com'), isNull);
    });

    test('getYoutubeVideoId matches various patterns', () {
      expect(getYoutubeVideoId('dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
      expect(getYoutubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'));
      expect(getYoutubeVideoId('https://youtu.be/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'));
      expect(getYoutubeVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'));
      expect(getYoutubeVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'));
      expect(getYoutubeVideoId('https://www.youtube.com/live/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'));
      expect(getYoutubeVideoId('https://example.com'), isNull);
    });

    test('getYoutubeEmbedParam', () {
      expect(getYoutubeEmbedParam('https://www.youtube.com/watch?v=123'),
          equals('https://www.youtube.com/watch?v=123'));
      expect(getYoutubeEmbedParam('https://youtu.be/12345678901'),
          equals('https://www.youtube.com/watch?v=12345678901'));
      expect(getYoutubeEmbedParam('invalid'), equals('invalid'));
    });

    test('buildYoutubeEmbedUrl', () {
      expect(
        buildYoutubeEmbedUrl('dQw4w9WgXcQ', queryParameters: {'rel': '0'}),
        equals(
          'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1&enablejsapi=1&origin=https%3A%2F%2Fwww.youtube-nocookie.com&widget_referrer=https%3A%2F%2Fwww.youtube-nocookie.com&rel=0',
        ),
      );
      expect(
        buildYoutubeEmbedUrl(
          'dQw4w9WgXcQ',
          queryParameters: {
            'enablejsapi': '0',
            'origin': 'https://example.com'
          },
        ),
        equals(
          'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1&enablejsapi=0&origin=https%3A%2F%2Fexample.com&widget_referrer=https%3A%2F%2Fwww.youtube-nocookie.com',
        ),
      );
      expect(buildYoutubeEmbedUrl('invalid'), isNull);
    });

    test('getSpotifyMetadata matches various patterns', () {
      expect(
        getSpotifyMetadata(
            'https://open.spotify.com/track/4cOdK2wGvV9m9X7S7O0WhS'),
        equals(('track', '4cOdK2wGvV9m9X7S7O0WhS')),
      );
      expect(
        getSpotifyMetadata(
            'https://open.spotify.com/album/1A2B3C4D5E6F7G8H9I0J'),
        equals(('album', '1A2B3C4D5E6F7G8H9I0J')),
      );
      expect(
        getSpotifyMetadata(
            'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM3M'),
        equals(('playlist', '37i9dQZF1DXcBWIGoYBM3M')),
      );
      expect(getSpotifyMetadata('https://example.com'), isNull);
    });

    test('buildSpotifyEmbedUrl', () {
      expect(
        buildSpotifyEmbedUrl('https://open.spotify.com/track/123'),
        equals('https://open.spotify.com/embed/track/123'),
      );
      expect(buildSpotifyEmbedUrl('invalid'), isNull);
    });

    test('getVimeoVideoId matches various patterns', () {
      expect(getVimeoVideoId('https://vimeo.com/76979871'), equals('76979871'));
      expect(getVimeoVideoId('https://vimeo.com/channels/staffpicks/76979871'),
          equals('76979871'));
      expect(getVimeoVideoId('https://vimeo.com/video/76979871'),
          equals('76979871'));
      expect(getVimeoVideoId('https://example.com'), isNull);
    });

    test('buildVimeoEmbedUrl', () {
      expect(
        buildVimeoEmbedUrl('https://vimeo.com/123'),
        equals('https://player.vimeo.com/video/123'),
      );
      expect(buildVimeoEmbedUrl('invalid'), isNull);
    });
  });
}
