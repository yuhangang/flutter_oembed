import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('GenericEmbedApi', () {
    const endpoint = 'https://example.com/oembed';
    const contentUrl = 'https://example.com/post/123';

    test('constructUrl builds correct URI', () {
      const api = GenericEmbedApi(endpoint);
      final uri = api.constructUrl(contentUrl);

      expect(uri.toString(), contains('url=${Uri.encodeComponent(contentUrl)}'));
      expect(uri.host, equals('example.com'));
    });

    test('constructUrl includes width parameter', () {
      const api = GenericEmbedApi(endpoint, width: 500);
      final uri = api.constructUrl(contentUrl);

      expect(uri.queryParameters['maxwidth'], equals('500'));
    });

    test('constructUrl includes custom query parameters', () {
      const api = GenericEmbedApi(endpoint);
      final uri = api.constructUrl(contentUrl, queryParameters: {'theme': 'dark'});

      expect(uri.queryParameters['theme'], equals('dark'));
    });

    test('constructUrl handles proxyUrl', () {
      const api = GenericEmbedApi(endpoint, proxyUrl: 'https://proxy.com');
      final uri = api.constructUrl(contentUrl);

      expect(uri.toString(), startsWith('https://proxy.com/https://example.com/oembed'));
    });

    test('handleErrorResponse returns correct exceptions', () {
      const api = GenericEmbedApi(endpoint);
      
      final error404 = api.handleErrorResponse(http.Response('', 404));
      expect(error404, isA<EmbedDataNotFoundException>());

      final error500 = api.handleErrorResponse(http.Response('', 500));
      expect(error500, isA<EmbedApisException>());
    });
  });
}
