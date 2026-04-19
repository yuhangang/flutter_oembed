import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/services/api/reddit_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class WebTestRedditEmbedApi extends RedditEmbedApi {
  const WebTestRedditEmbedApi({super.width});

  @override
  bool get isWeb => true;
}

void main() {
  group('RedditEmbedApi', () {
    test('constructUrl builds correct URI with width and dark theme', () {
      const api = RedditEmbedApi(width: 500);
      final uri = api.constructUrl('https://reddit.com/r/test',
          brightness: Brightness.dark);

      expect(uri.queryParameters['maxwidth'], equals('500'));
      expect(uri.queryParameters['theme'], equals('dark'));
      expect(uri.queryParameters['format'], equals('json'));
    });

    test('headers includes User-Agent', () {
      const api = RedditEmbedApi();
      expect(api.headers['User-Agent'], contains('flutter_embed'));
    });

    test('handleErrorResponse handles 404', () {
      const api = RedditEmbedApi();
      expect(api.handleErrorResponse(http.Response('', 404)),
          isA<EmbedDataNotFoundException>());
      expect(api.handleErrorResponse(http.Response('', 500)),
          isA<EmbedApisException>());
    });

    test('routes web requests through proxyUrl when provided', () async {
      const api = WebTestRedditEmbedApi(width: 568);
      final mockClient = MockHttpClient();
      registerFallbackValue(Uri.parse('https://example.com'));

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response('{"type":"rich","html":""}', 200));

      await api.getEmbedData(
        'https://www.reddit.com/r/flutterdev/comments/17yv8y8/how_to_implement_embed_in_flutter/',
        brightness: Brightness.light,
        proxyUrl: 'http://localhost:8080/',
        httpClient: mockClient,
      );

      final capturedUri = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured.first as Uri;

      expect(
        capturedUri.toString(),
        startsWith('http://localhost:8080/https://www.reddit.com/oembed?'),
      );
      expect(
        capturedUri.query,
        contains(
          'url=https%3A%2F%2Fwww.reddit.com%2Fr%2Fflutterdev%2Fcomments%2F17yv8y8%2Fhow_to_implement_embed_in_flutter%2F',
        ),
      );
    });
  });
}
