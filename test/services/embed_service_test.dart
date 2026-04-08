import 'dart:convert';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/embed_provider_config.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmbedService', () {
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    group('resolveRule()', () {
      test('should return a rule for YouTube URLs', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        final rule = EmbedService.resolveRule(url);

        expect(rule, isNotNull);
        expect(rule?.providerName, equals('YouTube'));
      });

      test('should return a rule for TikTok URLs', () {
        const url =
            'https://www.tiktok.com/@scout2015/video/6771039285231176966';
        final rule = EmbedService.resolveRule(url);

        expect(rule, isNotNull);
        expect(rule?.providerName, equals('TikTok'));
      });

      test('should return null for unknown URLs', () {
        const url = 'https://example.com/unknown';
        final rule = EmbedService.resolveRule(url);

        expect(rule, isNull);
      });

      test('should use dynamic discovery when enabled in the config', () {
        const url = 'https://www.facebook.com/facebook/posts/10158716223136729';
        final rule = EmbedService.resolveRule(url,
            config: const EmbedConfig(useDynamicDiscovery: true));

        expect(rule, isNotNull);
        expect(rule?.providerName, anyOf('Facebook', 'Facebook Post'));
      });

      test('should handle subdomains correctly (e.g., m.youtube.com)', () {
        const url = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ';
        final rule = EmbedService.resolveRule(url,
            config: const EmbedConfig(useDynamicDiscovery: true));
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('YouTube'));
      });

      test(
          'should not fall back to the first snapshot rule when the host matches but the pattern does not',
          () {
        const url = 'https://www.youtube.com/channel/UC123456789';
        final rule = EmbedService.resolveRule(url,
            config: const EmbedConfig(useDynamicDiscovery: true));

        expect(rule, isNull);
      });

      test('should use default rules when no config is provided', () {
        final rule =
            EmbedService.resolveRule('https://youtube.com/watch?v=123');
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('YouTube'));
      });

      test('should match wildcard domains in snapshot (e.g., flickr.com)', () {
        const url = 'https://www.flickr.com/photos/123';
        final rule = EmbedService.resolveRule(url,
            config: const EmbedConfig(useDynamicDiscovery: true));
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('Flickr'));
      });

      test('should discover Tumblr as a verified provider by default', () {
        const url = 'https://www.tumblr.com/post/123';
        final rule = EmbedService.resolveRule(url);
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('Tumblr'));
        expect(rule?.isVerified, isTrue);
      });

      test(
          'should resolve Tumblr endpoint for photomatt URL shape from discovery example',
          () {
        const url =
            'https://www.tumblr.com/photomatt/765038139535097856/the-new-auto-follow-on-tumblr-is-so-good';
        final rule = EmbedService.resolveRule(url,
            config: const EmbedConfig(useDynamicDiscovery: true));
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('Tumblr'));

        final api = EmbedService.getEmbedApiByEmbedType(
          EmbedLoaderParam(
            url: url,
            embedType: EmbedType.other,
            width: 640,
          ),
        );
        expect(api, isA<GenericEmbedApi>());
        expect(api.baseUrl, equals('https://www.tumblr.com/oembed/1.0'));

        final requestUri = api.constructUrl(url);
        expect(requestUri.origin + requestUri.path,
            equals('https://www.tumblr.com/oembed/1.0'));
        expect(requestUri.queryParameters['url'], equals(url));
      });
    });

    group('resolveIframeUrl()', () {
      test('should return the correct iframe URL for YouTube', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        const config = EmbedConfig(
          providers: EmbedProviderConfig(
            providerRenderModes: {'YouTube': EmbedRenderMode.iframe},
          ),
        );

        final iframeUrl = EmbedService.resolveIframeUrl(url, config: config);

        expect(iframeUrl, contains('youtube.com/embed/dQw4w9WgXcQ'));
      });

      test('should return null if the provider render mode is not iframe', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        const config = EmbedConfig(
          providers: EmbedProviderConfig(
            providerRenderModes: {'YouTube': EmbedRenderMode.oembed},
          ),
        );

        final iframeUrl = EmbedService.resolveIframeUrl(url, config: config);

        expect(iframeUrl, isNull);
      });

      test('should correctly append query parameters to the iframe URL', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        const config = EmbedConfig(
          providers: EmbedProviderConfig(
            providerRenderModes: {'YouTube': EmbedRenderMode.iframe},
          ),
        );

        final iframeUrl = EmbedService.resolveIframeUrl(url,
            config: config, queryParameters: {'rel': '0'});

        expect(iframeUrl, contains('rel=0'));
      });
    });

    group('getResult()', () {
      test('should fetch data using the provided httpClient', () async {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        final param = EmbedLoaderParam(
          url: url,
          embedType: EmbedType.youtube,
          width: 640,
        );

        final expectedResponse = {
          'version': '1.0',
          'type': 'video',
          'html': '<div>YouTube Video</div>',
        };

        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response(jsonEncode(expectedResponse), 200));

        final result = await EmbedService.getResult(
          param: param,
          httpClient: mockClient,
          cacheConfig: const EmbedCacheConfig(enabled: false),
        );

        expect(result.html, equals('<div>YouTube Video</div>'));
        verify(() => mockClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('should use the httpClient and cache configuration from EmbedConfig',
          () async {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        final param = EmbedLoaderParam(
          url: url,
          embedType: EmbedType.youtube,
          width: 640,
        );

        final expectedResponse = {
          'version': '1.0',
          'type': 'video',
          'html': '<div>YouTube Video</div>',
        };

        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer(
                (_) async => http.Response(jsonEncode(expectedResponse), 200));

        final result = await EmbedService.getResult(
          param: param,
          config: EmbedConfig(
              httpClient: mockClient,
              cache: const EmbedCacheConfig(enabled: false)),
          httpClient: mockClient,
        );

        expect(result.html, equals('<div>YouTube Video</div>'));
      });
    });

    group('getEmbedApiByEmbedType()', () {
      test('should return the correct API instance for a given EmbedType', () {
        final param = EmbedLoaderParam(
          url: 'https://youtube.com/watch?v=123',
          embedType: EmbedType.youtube,
          width: 640,
        );
        final api = EmbedService.getEmbedApiByEmbedType(param);
        expect(api.baseUrl, contains('youtube.com'));
      });

      test(
          'should throw EmbedApisException if no rule matches and not a likely endpoint',
          () {
        final param = EmbedLoaderParam(
          url: 'https://unknown-provider.com/123',
          embedType: EmbedType.other,
          width: 640,
        );
        expect(() => EmbedService.getEmbedApiByEmbedType(param),
            throwsA(isA<EmbedProviderNotFoundException>()));
      });

      test(
          'should allow fallback to GenericEmbedApi ONLY if it looks like an endpoint',
          () {
        final param = EmbedLoaderParam(
          url:
              'https://unknown-provider.com/api/oembed.json?url=https://target.com',
          embedType: EmbedType.other,
          width: 640,
        );
        final api = EmbedService.getEmbedApiByEmbedType(param);
        expect(api, isA<GenericEmbedApi>());
        expect(api.baseUrl, contains('/oembed.json'));
      });
    });
  });
}
