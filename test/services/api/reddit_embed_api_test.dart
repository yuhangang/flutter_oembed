import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/services/api/reddit_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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
  });
}
