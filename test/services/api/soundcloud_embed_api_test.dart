import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/models/soundcloud_embed_params.dart';
import 'package:flutter_embed/src/services/api/soundcloud_embed_api.dart';

void main() {
  group('SoundCloudEmbedParams', () {
    test('toMap() converts parameters correctly', () {
      const params = SoundCloudEmbedParams(
        autoPlay: true,
        showComments: false,
        color: 'ff00ff',
        maxheight: 166,
      );

      final map = params.toMap();

      expect(map['auto_play'], 'true');
      expect(map['show_comments'], 'false');
      expect(map['color'], 'ff00ff');
      expect(map['maxheight'], '166');
    });
  });

  group('SoundCloudEmbedApi', () {
    test('constructUrl includes base parameters and format=json', () {
      const api = SoundCloudEmbedApi(640);
      final uri = api.constructUrl('https://soundcloud.com/forss/flickermood');

      expect(uri.scheme, 'https');
      expect(uri.host, 'soundcloud.com');
      expect(uri.path, '/oembed');
      expect(uri.queryParameters['url'],
          'https://soundcloud.com/forss/flickermood');
      expect(uri.queryParameters['format'], 'json');
      expect(uri.queryParameters['maxwidth'], '640');
    });

    test('constructUrl includes SoundCloudEmbedParams', () {
      const soundCloudParams = SoundCloudEmbedParams(
        autoPlay: true,
        color: '00aabb',
      );
      const api = SoundCloudEmbedApi(640, soundCloudParams: soundCloudParams);
      final uri = api.constructUrl('https://soundcloud.com/forss/flickermood');

      expect(uri.queryParameters['auto_play'], 'true');
      expect(uri.queryParameters['color'], '00aabb');
    });

    test('constructUrl merges queryParameters', () {
      const api = SoundCloudEmbedApi(640);
      final uri = api.constructUrl(
        'https://soundcloud.com/forss/flickermood',
        queryParameters: {'custom': 'value'},
      );

      expect(uri.queryParameters['custom'], 'value');
      expect(uri.queryParameters['format'], 'json');
    });
  });
}
