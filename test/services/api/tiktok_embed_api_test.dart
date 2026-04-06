import 'package:flutter_embed/src/services/api/tiktok_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TikTokEmbedApi', () {
    test('constructUrl returns correct URI', () {
      const api = TikTokEmbedApi();
      final uri = api.constructUrl('https://www.tiktok.com/@user/video/123');

      expect(uri.toString(), contains('url=${Uri.encodeComponent('https://www.tiktok.com/@user/video/123')}'));
      expect(uri.host, equals('www.tiktok.com'));
      expect(uri.path, equals('/oembed'));
    });

    test('baseUrl is correct', () {
      const api = TikTokEmbedApi();
      expect(api.baseUrl, equals('https://www.tiktok.com/oembed'));
    });
  });
}
