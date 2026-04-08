import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_oembed/src/services/api/x_embed_api.dart';

void main() {
  group('XEmbedApi', () {
    const api = XEmbedApi();

    test('constructUrl includes URL and theme=light for light brightness', () {
      final uri = api.constructUrl(
        'https://twitter.com/x/status/123',
        brightness: Brightness.light,
      );
      expect(uri.queryParameters['url'], 'https://twitter.com/x/status/123');
      expect(uri.queryParameters['theme'], 'light');
    });

    test('constructUrl includes theme=dark for dark brightness', () {
      final uri = api.constructUrl(
        'https://twitter.com/x/status/123',
        brightness: Brightness.dark,
      );
      expect(uri.queryParameters['theme'], 'dark');
    });

    test('constructUrl maps locale to localeMap correctly', () {
      final uri = api.constructUrl(
        'https://twitter.com/x/status/123',
        locale: 'ms',
      );
      expect(uri.queryParameters['lang'], 'msa');
    });

    test('baseUrl points to twitter publish endpoint', () {
      expect(api.baseUrl, 'https://publish.twitter.com/oembed');
    });

    test('constructUrl includes chrome parameters', () {
      final uri = api.constructUrl('https://twitter.com/x/status/123');
      expect(uri.queryParameters['chrome'], isNotNull);
    });
  });
}
