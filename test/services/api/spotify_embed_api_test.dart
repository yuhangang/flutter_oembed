import 'package:flutter_oembed/src/services/api/spotify_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotifyEmbedApi', () {
    test('constructUrl returns correct URI', () {
      const api = SpotifyEmbedApi();
      final uri = api.constructUrl('https://open.spotify.com/track/123');

      expect(
          uri.toString(),
          contains(
              'url=${Uri.encodeComponent('https://open.spotify.com/track/123')}'));
      expect(uri.host, equals('open.spotify.com'));
      expect(uri.path, equals('/oembed'));
    });

    test('baseUrl is correct', () {
      const api = SpotifyEmbedApi();
      expect(api.baseUrl, equals('https://open.spotify.com/oembed'));
    });
  });
}
