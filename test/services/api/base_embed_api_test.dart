import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

// - [x] Improve naming in `test/utils/embed_matchers_test.dart`
// - [x] Improve naming in `test/controllers/embed_navigation_handler_test.dart`
// - [x] Improve naming in `test/services/provider_registry_test.dart`
// - [x] Improve naming in `test/services/embed_service_test.dart`
// - [x] Improve naming in `test/controllers/embed_webview_driver_test.dart`
// - [x] Improve naming in `test/widgets/embed_webview_test.dart`
// - [x] Improve naming in `test/widgets/youtube_embed_player_test.dart`
// - [x] Improve naming in `test/widgets/tiktok_embed_player_test.dart`
// - [x] Improve naming in `test/logging/embed_logger_test.dart`
// - [x] Improve naming in `test/services/api/*.dart`

class MockHttpClient extends Mock implements http.Client {}

class MockCacheProvider extends Mock implements EmbedCacheProvider {}

class TestEmbedApi extends GenericEmbedApi {
  const TestEmbedApi(super.endpoint, {super.headers});

  @override
  EmbedData oembedResponseModifier(EmbedData response) {
    return response.copyWith(title: 'Modified');
  }
}

void main() {
  group('GenericEmbedApi', () {
    const endpoint = 'https://example.com/oembed';
    const contentUrl = 'https://example.com/post/123';
    late MockHttpClient mockClient;
    late MockCacheProvider mockCache;

    setUp(() {
      mockClient = MockHttpClient();
      mockCache = MockCacheProvider();
      registerFallbackValue(Uri.parse('https://example.com'));
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(const Duration(seconds: 1));
      registerFallbackValue(const EmbedConfig());
    });

    group('constructUrl()', () {
      test('should build a correct URI with the default URL parameter', () {
        const api = GenericEmbedApi(endpoint);
        final uri = api.constructUrl(contentUrl);

        expect(
            uri.toString(), contains('url=${Uri.encodeComponent(contentUrl)}'));
        expect(uri.host, equals('example.com'));
      });

      test('should include custom query parameters in the built URI', () {
        const api = GenericEmbedApi(endpoint);
        final uri =
            api.constructUrl(contentUrl, queryParameters: {'custom': 'value'});

        expect(uri.queryParameters['custom'], equals('value'));
      });

      test('should ignore brightness because generic oembed has no theme map',
          () {
        const api = GenericEmbedApi(endpoint);
        final lightUri =
            api.constructUrl(contentUrl, brightness: Brightness.light);
        final darkUri =
            api.constructUrl(contentUrl, brightness: Brightness.dark);

        expect(darkUri.queryParameters, equals(lightUri.queryParameters));
        expect(darkUri.queryParameters.containsKey('theme'), isFalse);
      });

      test(
          'should correctly handle and prepend a proxyUrl if provided in config',
          () {
        const api = GenericEmbedApi(endpoint);
        final uri = api.constructUrl(
          contentUrl,
          config: const EmbedConfig(proxyUrl: 'https://proxy.com'),
        );
        expect(uri.toString(),
            startsWith('https://proxy.com/https://example.com/oembed'));
      });
    });

    group('baseUrl', () {
      test('should correctly handle the {format} placeholder in the endpoint',
          () {
        const api = GenericEmbedApi('https://test.com/oembed.{format}');
        expect(api.baseUrl, equals('https://test.com/oembed.json'));
      });
    });

    group('headers', () {
      test('should correctly store and expose the provided headers', () {
        const api = GenericEmbedApi(endpoint, headers: {'X-Custom': 'Value'});
        expect(api.headers['X-Custom'], equals('Value'));
      });
    });

    group('getEmbedData()', () {
      test('should fetch data from the network when the cache is disabled',
          () async {
        const api = TestEmbedApi(endpoint);
        final expectedData = {
          'version': '1.0',
          'type': 'rich',
          'html': '<div>Test</div>',
        };

        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response(jsonEncode(expectedData), 200));

        final result = await api.getEmbedData(
          contentUrl,
          cacheProvider: mockCache,
          cacheConfig: const EmbedCacheConfig(enabled: false),
          httpClient: mockClient,
        );

        expect(result.html, equals('<div>Test</div>'));
        expect(result.title, equals('Modified')); // Check modifier
        verify(() => mockClient.get(any(), headers: any(named: 'headers')))
            .called(1);
        verifyNever(() => mockCache.getFileFromCache(any<String>()));
      });

      test('should fetch data from the cache when it is available', () async {
        const api = TestEmbedApi(endpoint);
        final expectedData = {
          'version': '1.0',
          'type': 'rich',
          'html': '<div>Cached</div>',
        };

        when(() => mockCache.getFileFromCache(any<String>())).thenAnswer(
            (_) async =>
                Uint8List.fromList(utf8.encode(jsonEncode(expectedData))));

        final result = await api.getEmbedData(
          contentUrl,
          cacheProvider: mockCache,
          cacheConfig: const EmbedCacheConfig(enabled: true),
          httpClient: mockClient,
        );

        expect(result.html, equals('<div>Cached</div>'));
        verify(() => mockCache.getFileFromCache(any<String>())).called(1);
        verifyNever(
            () => mockClient.get(any(), headers: any(named: 'headers')));
      });

      test('should save successfully fetched network data to the cache',
          () async {
        const api = TestEmbedApi(endpoint);
        final expectedData = {
          'version': '1.0',
          'type': 'rich',
          'html': '<div>Test</div>',
        };

        when(() => mockCache.getFileFromCache(any<String>()))
            .thenAnswer((_) async => null);
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response(jsonEncode(expectedData), 200));
        when(() => mockCache.putFile(any<String>(), any<Uint8List>(),
            maxAge: any(named: 'maxAge'))).thenAnswer((_) async {});

        await api.getEmbedData(
          contentUrl,
          cacheProvider: mockCache,
          cacheConfig: const EmbedCacheConfig(enabled: true),
          httpClient: mockClient,
        );

        verify(() => mockCache.putFile(any<String>(), any<Uint8List>(),
            maxAge: any(named: 'maxAge'))).called(1);
      });

      test('should throw an EmbedDataNotFoundException on an error response',
          () async {
        const api = TestEmbedApi(endpoint);

        when(() => mockCache.getFileFromCache(any<String>()))
            .thenAnswer((_) async => null);
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        expect(
          () => api.getEmbedData(
            contentUrl,
            cacheProvider: mockCache,
            cacheConfig: const EmbedCacheConfig(enabled: true),
            httpClient: mockClient,
          ),
          throwsA(isA<EmbedDataNotFoundException>()),
        );
      });
    });

    group('getCachedResult()', () {
      test('should return null when a cache error occurs', () async {
        const api = TestEmbedApi(endpoint);
        when(() => mockCache.getFileFromCache(any<String>()))
            .thenThrow(Exception('Cache error'));

        final result = await api.getCachedResult(
          Uri.parse('https://example.com'),
          cacheProvider: mockCache,
        );
        expect(result, isNull);
      });

      test('should return null when the cached file bytes are empty', () async {
        const api = TestEmbedApi(endpoint);

        when(() => mockCache.getFileFromCache(any<String>()))
            .thenAnswer((_) async => Uint8List(0));

        final result = await api.getCachedResult(
          Uri.parse('https://example.com'),
          cacheProvider: mockCache,
        );
        expect(result, isNull);
      });
    });

    group('setCachedResult()', () {
      test('should handle and swallow errors when saving to cache fails',
          () async {
        const api = TestEmbedApi(endpoint);
        when(() => mockCache.putFile(any<String>(), any<Uint8List>(),
            maxAge: any(named: 'maxAge'))).thenThrow(Exception('Cache error'));

        await api.setCachedResult(
          Uri.parse('https://example.com'),
          const EmbedData(html: ''),
          cacheProvider: mockCache,
        );
        // No crash means it's handled
      });

      test('should use a 7-day TTL when no specific TTL is provided', () async {
        const api = TestEmbedApi(endpoint);

        when(() => mockCache.putFile(any<String>(), any<Uint8List>(),
            maxAge: any(named: 'maxAge'))).thenAnswer((_) async {});

        await api.setCachedResult(
          Uri.parse('https://example.com'),
          const EmbedData(html: 'test'),
          cacheProvider: mockCache,
        );

        verify(() => mockCache.putFile(any<String>(), any<Uint8List>(),
            maxAge: const Duration(days: 7))).called(1);
      });
    });

    group('handleErrorResponse()', () {
      test('should return an EmbedApisException for non-404 status codes', () {
        const api = GenericEmbedApi(endpoint);
        expect(api.handleErrorResponse(http.Response('', 500)),
            isA<EmbedApisException>());
      });
    });
  });
}
