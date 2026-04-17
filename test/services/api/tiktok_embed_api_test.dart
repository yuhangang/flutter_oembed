import 'package:flutter_oembed/src/models/params/tiktok_embed_params.dart';
import 'package:flutter_oembed/src/services/api/tiktok_embed_api.dart';
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

      test('should inclusion TikTokEmbedParams in the query parameters', () {
        const api = TikTokEmbedApi(
          tiktokParams: TikTokEmbedParams(
            autoplay: true,
            muted: true,
            controls: false,
          ),
        );
        final uri = api.constructUrl('https://www.tiktok.com/@user/video/123');

        expect(uri.queryParameters['autoplay'], equals('1'));
        expect(uri.queryParameters['muted'], equals('1'));
        expect(uri.queryParameters['controls'], equals('0'));
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
