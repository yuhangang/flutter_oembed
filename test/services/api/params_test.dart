import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_oembed/src/models/params/vimeo_embed_params.dart';
import 'package:flutter_oembed/src/models/params/meta_embed_params.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/services/api/vimeo_embed_api.dart';
import 'package:flutter_oembed/src/services/api/meta_embed_api.dart';

void main() {
  group('VimeoEmbedParams', () {
    test('toMap() converts parameters correctly', () {
      const params = VimeoEmbedParams(
        autoplay: true,
        loop: false,
        color: 'ff0000',
        speed: 1.5,
      );

      final map = params.toMap();

      expect(map['autoplay'], 'true');
      expect(map['loop'], 'false');
      expect(map['color'], 'ff0000');
      expect(map['speed'], '1.5');
    });

    test('VimeoEmbedApi constructUrl includes parameters', () {
      const vimeoParams = VimeoEmbedParams(autoplay: true);
      const api = VimeoEmbedApi(640, vimeoParams: vimeoParams);

      final uri = api.constructUrl('https://vimeo.com/12345');

      expect(uri.queryParameters['autoplay'], 'true');
      expect(uri.queryParameters['maxwidth'], '640');
    });
  });

  group('MetaEmbedParams', () {
    test('toMap() converts parameters correctly', () {
      const params = MetaEmbedParams(
        adaptContainerWidth: true,
        hideCover: false,
        hidecaption: true,
        maxheight: 500,
        omitscript: true,
        sdklocale: 'en_US',
        showFacepile: false,
        showPosts: true,
        smallHeader: false,
        useiframe: true,
      );

      final map = params.toMap();

      expect(map['adapt_container_width'], 'true');
      expect(map['hide_cover'], 'false');
      expect(map['hidecaption'], 'true');
      expect(map['maxheight'], '500');
      expect(map['omitscript'], 'true');
      expect(map['sdklocale'], 'en_US');
      expect(map['show_facepile'], 'false');
      expect(map['show_posts'], 'true');
      expect(map['small_header'], 'false');
      expect(map['useiframe'], 'true');
    });

    test('MetaEmbedApi constructUrl includes parameters for Facebook Page', () {
      const metaParams = MetaEmbedParams(smallHeader: true, hideCover: true);
      const api = MetaEmbedApi(
        EmbedType.facebook,
        640,
        'appId',
        'token',
        metaParams: metaParams,
      );

      final uri = api.constructUrl('https://facebook.com/page');

      expect(uri.queryParameters['small_header'], 'true');
      expect(uri.queryParameters['hide_cover'], 'true');
      expect(uri.queryParameters['maxwidth'], '640');
    });

    test('MetaEmbedApi constructUrl includes parameters for Instagram', () {
      const metaParams = MetaEmbedParams(hidecaption: true);
      const api = MetaEmbedApi(
        EmbedType.instagram,
        640,
        'appId',
        'token',
        metaParams: metaParams,
      );

      final uri = api.constructUrl('https://instagram.com/p/123');

      expect(uri.queryParameters['hidecaption'], 'true');
    });

    test('MetaEmbedApi constructUrl uses Threads endpoint and base URL', () {
      const api = MetaEmbedApi(
        EmbedType.threads,
        640,
        'appId',
        'token',
      );

      final uri = api.constructUrl('https://threads.net/@user/post/123');

      expect(uri.host, 'graph.threads.net');
      expect(uri.path, '/v1.0/oembed');
    });
  });
}
