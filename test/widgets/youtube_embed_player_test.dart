import 'package:flutter_embed/src/widgets/youtube_embed_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildYoutubePlayerHtml', () {
    test('uses the configured host and mirrors it into origin fields', () {
      final html = buildYoutubePlayerHtml(
        playerId: 'player-1',
        videoId: '00BHXAzYRTA',
        host: kYoutubeNoCookiePlayerHost,
        playerVars: const {
          'playsinline': 1,
          'controls': 1,
          'origin': kYoutubeNoCookiePlayerHost,
          'widget_referrer': kYoutubeNoCookiePlayerHost,
        },
      );

      expect(html, contains('host: "https://www.youtube-nocookie.com"'));
      expect(html, contains('videoId: "00BHXAzYRTA"'));
      expect(html, contains('"playsinline":1'));
      expect(html, contains('"origin":"https://www.youtube-nocookie.com"'));
      expect(
        html,
        contains('"widget_referrer":"https://www.youtube-nocookie.com"'),
      );
    });

    test('allows origin to be passed through playerVars when enabled', () {
      final html = buildYoutubePlayerHtml(
        playerId: 'player-2',
        videoId: '00BHXAzYRTA',
        host: kDefaultYoutubePlayerHost,
        playerVars: const {
          'playsinline': 1,
          'origin': kYoutubeNoCookiePlayerHost,
        },
      );

      expect(html, contains('"origin":"https://www.youtube-nocookie.com"'));
    });
  });
}
