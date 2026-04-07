import 'package:flutter_embed/src/services/api/tiktok_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TikTokEmbedApi', () {
    group('constructUrl()', () {
      test('should return the correct URI for a given TikTok video URL', () {
        const api = TikTokEmbedApi();
        final uri = api.constructUrl('https://www.tiktok.com/@user/video/123');

        expect(
            uri.toString(),
            contains(
                'url=${Uri.encodeComponent('https://www.tiktok.com/@user/video/123')}'));
        expect(uri.host, equals('www.tiktok.com'));
        expect(uri.path, equals('/oembed'));
      });
    });

    group('baseUrl', () {
      test('should correctly expose the fixed TikTok oEmbed endpoint', () {
        const api = TikTokEmbedApi();
        expect(api.baseUrl, equals('https://www.tiktok.com/oembed'));
      });
    });
  });
}
