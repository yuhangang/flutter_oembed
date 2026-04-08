import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/soundcloud_embed_params.dart';
import 'package:flutter_oembed/src/models/vimeo_embed_params.dart';
import 'package:flutter_oembed/src/models/x_embed_params.dart';
import 'package:flutter_oembed/src/services/api/soundcloud_embed_api.dart';
import 'package:flutter_oembed/src/services/api/spotify_embed_api.dart';
import 'package:flutter_oembed/src/services/api/tiktok_embed_api.dart';
import 'package:flutter_oembed/src/services/api/vimeo_embed_api.dart';
import 'package:flutter_oembed/src/services/api/x_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('SoundCloudEmbedApi', () {
    test('constructUrl with params', () {
      const api = SoundCloudEmbedApi(640,
          soundCloudParams: SoundCloudEmbedParams(autoPlay: true));
      final uri = api.constructUrl('https://soundcloud.com/test');
      expect(uri.queryParameters['auto_play'], equals('true'));
      expect(uri.queryParameters['maxwidth'], equals('640'));
    });

    test('handleErrorResponse', () {
      const api = SoundCloudEmbedApi(640);
      expect(api.handleErrorResponse(http.Response('', 404)),
          isA<EmbedDataNotFoundException>());
      expect(api.handleErrorResponse(http.Response('', 500)),
          isA<EmbedApisException>());
    });

    test('constructUrl ignores brightness', () {
      const api = SoundCloudEmbedApi(640);
      final lightUri =
          api.constructUrl('https://soundcloud.com/test', brightness: Brightness.light);
      final darkUri =
          api.constructUrl('https://soundcloud.com/test', brightness: Brightness.dark);

      expect(darkUri.queryParameters, equals(lightUri.queryParameters));
      expect(darkUri.queryParameters.containsKey('theme'), isFalse);
    });
  });

  group('SpotifyEmbedApi', () {
    test('constructUrl', () {
      const api = SpotifyEmbedApi();
      final uri = api.constructUrl('https://spotify.com/track/1',
          queryParameters: {'custom': '1'});
      expect(uri.queryParameters['url'], equals('https://spotify.com/track/1'));
      expect(uri.queryParameters['custom'], equals('1'));
    });

    test('handleErrorResponse', () {
      const api = SpotifyEmbedApi();
      expect(api.handleErrorResponse(http.Response('', 404)),
          isA<EmbedDataNotFoundException>());
      expect(api.handleErrorResponse(http.Response('', 500)),
          isA<EmbedApisException>());
    });

    test('constructUrl ignores brightness', () {
      const api = SpotifyEmbedApi();
      final lightUri = api.constructUrl(
        'https://spotify.com/track/1',
        brightness: Brightness.light,
      );
      final darkUri = api.constructUrl(
        'https://spotify.com/track/1',
        brightness: Brightness.dark,
      );

      expect(darkUri.queryParameters, equals(lightUri.queryParameters));
      expect(darkUri.queryParameters.containsKey('theme'), isFalse);
    });
  });

  group('TikTokEmbedApi', () {
    test('constructUrl', () {
      const api = TikTokEmbedApi();
      final uri = api.constructUrl('https://tiktok.com/video/1');
      expect(uri.queryParameters['url'], equals('https://tiktok.com/video/1'));
    });
    test('handleErrorResponse always returns EmbedApisException', () {
      const api = TikTokEmbedApi();
      expect(api.handleErrorResponse(http.Response('', 404)),
          isA<EmbedApisException>());
    });

    test('constructUrl ignores brightness', () {
      const api = TikTokEmbedApi();
      final lightUri = api.constructUrl(
        'https://tiktok.com/video/1',
        brightness: Brightness.light,
      );
      final darkUri = api.constructUrl(
        'https://tiktok.com/video/1',
        brightness: Brightness.dark,
      );

      expect(darkUri.queryParameters, equals(lightUri.queryParameters));
      expect(darkUri.queryParameters.containsKey('theme'), isFalse);
    });
  });

  group('VimeoEmbedApi', () {
    test('constructUrl and modifier', () {
      const api = VimeoEmbedApi(640, vimeoParams: VimeoEmbedParams(loop: true));
      final uri =
          api.constructUrl('https://vimeo.com/1', queryParameters: {'a': 'b'});
      expect(uri.queryParameters['loop'], equals('true'));
      expect(uri.queryParameters['a'], equals('b'));

      // ignore: prefer_const_constructors
      final data =
          const EmbedData(html: '<iframe src="//player.vimeo.com"></iframe>');
      final modified = api.oembedResponseModifier(data);
      expect(modified.html, contains('src="https://player.vimeo.com"'));
    });

    test('handleErrorResponse', () {
      const api = VimeoEmbedApi(640);
      expect(api.handleErrorResponse(http.Response('', 404)),
          isA<EmbedDataNotFoundException>());
      expect(api.handleErrorResponse(http.Response('', 500)),
          isA<EmbedApisException>());
    });

    test('constructUrl ignores brightness', () {
      const api = VimeoEmbedApi(640);
      final lightUri =
          api.constructUrl('https://vimeo.com/1', brightness: Brightness.light);
      final darkUri =
          api.constructUrl('https://vimeo.com/1', brightness: Brightness.dark);

      expect(darkUri.queryParameters, equals(lightUri.queryParameters));
      expect(darkUri.queryParameters.containsKey('theme'), isFalse);
    });
  });

  group('XEmbedApi', () {
    test('constructUrl with locale and brightness', () {
      const api = XEmbedApi(xParams: XEmbedParams(dnt: true));
      final uri = api.constructUrl('https://x.com/post/1',
          locale: 'ms', brightness: Brightness.dark);
      expect(uri.queryParameters['lang'], equals('msa'));
      expect(uri.queryParameters['theme'], equals('dark'));
      expect(uri.queryParameters['dnt'], equals('true'));
    });

    test('handleErrorResponse handles 403', () {
      const api = XEmbedApi();
      expect(api.handleErrorResponse(http.Response('', 403)),
          isA<EmbedDataRestrictedAccessException>());
    });
  });
}
