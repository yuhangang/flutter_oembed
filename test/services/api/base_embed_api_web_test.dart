import 'dart:convert';

import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class WebTestEmbedApi extends GenericEmbedApi {
  final bool _mockIsWeb;

  const WebTestEmbedApi(super.endpoint, {super.proxyUrl, bool mockIsWeb = true})
      : _mockIsWeb = mockIsWeb;

  @override
  bool get isWeb => _mockIsWeb;
}

void main() {
  group('BaseEmbedApi Web Proxy logic', () {
    const endpoint = 'https://example.com/oembed';
    const contentUrl = 'https://example.com/post/123';
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    test('should prepend proxyUrl on Web when provided', () async {
      const proxy = 'http://localhost:8080/';
      const api = WebTestEmbedApi(endpoint, proxyUrl: proxy);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'type': 'rich', 'html': ''}), 200));

      await api.getEmbedData(contentUrl, httpClient: mockClient);

      final capturedUri = verify(() =>
              mockClient.get(captureAny(), headers: any(named: 'headers')))
          .captured
          .first as Uri;

      // Should NOT have double slash even if proxy has trailing slash
      // http://localhost:8080/https://example.com/oembed...
      expect(capturedUri.toString(),
          startsWith('http://localhost:8080/https://example.com/oembed'));
      expect(capturedUri.toString(), isNot(contains('8080//http')));
    });

    test('should NOT prepend proxyUrl on Web if proxyUrl is empty', () async {
      const api = WebTestEmbedApi(endpoint, proxyUrl: '');

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'type': 'rich', 'html': ''}), 200));

      await api.getEmbedData(contentUrl, httpClient: mockClient);

      final capturedUri = verify(() =>
              mockClient.get(captureAny(), headers: any(named: 'headers')))
          .captured
          .first as Uri;

      expect(capturedUri.toString(), startsWith('https://example.com/oembed'));
    });

    test('should NOT prepend proxyUrl if not on Web', () async {
      const proxy = 'http://localhost:8080/';
      const api = WebTestEmbedApi(endpoint, proxyUrl: proxy, mockIsWeb: false);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'type': 'rich', 'html': ''}), 200));

      await api.getEmbedData(contentUrl, httpClient: mockClient);

      final capturedUri = verify(() =>
              mockClient.get(captureAny(), headers: any(named: 'headers')))
          .captured
          .first as Uri;

      expect(capturedUri.toString(), startsWith('https://example.com/oembed'));
    });
  });
}
