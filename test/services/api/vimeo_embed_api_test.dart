import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/params/vimeo_embed_params.dart';
import 'package:flutter_oembed/src/services/api/vimeo_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VimeoEmbedApi', () {
    test('constructUrl returns correct URI with width and format', () {
      const api = VimeoEmbedApi(640);
      final uri = api.constructUrl('https://vimeo.com/123');

      expect(uri.queryParameters['url'], equals('https://vimeo.com/123'));
      expect(uri.queryParameters['maxwidth'], equals('640'));
      expect(uri.queryParameters['format'], equals('json'));
    });

    test('constructUrl includes VimeoEmbedParams', () {
      final params = const VimeoEmbedParams(autoplay: true, loop: true);
      final api = VimeoEmbedApi(640, vimeoParams: params);
      final uri = api.constructUrl('https://vimeo.com/123');

      expect(uri.queryParameters['autoplay'], equals('true'));
      expect(uri.queryParameters['loop'], equals('true'));
    });

    test('oembedResponseModifier fixes protocol-relative URLs', () {
      const api = VimeoEmbedApi(640);
      final data = const EmbedData(
        url: 'https://vimeo.com/123',
        html: '<iframe src="//player.vimeo.com/video/123"></iframe>',
        providerName: 'Vimeo',
        type: 'video',
      );

      final modified = api.oembedResponseModifier(data);
      expect(
          modified.html, contains('src="https://player.vimeo.com/video/123"'));
    });

    test('headers includes Referer', () {
      const api = VimeoEmbedApi(640);
      expect(api.headers['Referer'], equals('https://vimeo.com/'));
    });
  });
}
