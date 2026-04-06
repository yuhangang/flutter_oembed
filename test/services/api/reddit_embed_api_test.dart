import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/services/api/reddit_embed_api.dart';

void main() {
  group('RedditEmbedApi', () {
    const api = RedditEmbedApi();

    test('constructUrl includes URL and format=json', () {
      final uri =
          api.constructUrl('https://www.reddit.com/r/flutterdev/comments/123/');
      expect(uri.queryParameters['url'],
          'https://www.reddit.com/r/flutterdev/comments/123/');
      expect(uri.queryParameters['format'], 'json');
    });

    test('constructUrl includes maxwidth when width is provided', () {
      const apiWithWidth = RedditEmbedApi(width: 500);
      final uri = apiWithWidth
          .constructUrl('https://www.reddit.com/r/flutterdev/comments/123/');
      expect(uri.queryParameters['maxwidth'], '500');
    });

    test('constructUrl includes theme=dark for dark brightness', () {
      final uri = api.constructUrl(
        'https://www.reddit.com/r/flutterdev/comments/123/',
        brightness: Brightness.dark,
      );
      expect(uri.queryParameters['theme'], 'dark');
    });

    test('headers includes required User-Agent for Reddit', () {
      expect(api.headers['User-Agent'], contains('flutter_embed'));
    });

    test('baseUrl points to reddit oembed endpoint', () {
      expect(api.baseUrl, 'https://www.reddit.com/oembed');
    });
  });
}
