import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/configs/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/core/embed_renderer.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockCacheProvider extends Mock implements EmbedCacheProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmbedService', () {
    late MockHttpClient mockClient;
    late MockCacheProvider mockCacheProvider;

    setUp(() {
      mockClient = MockHttpClient();
      mockCacheProvider = MockCacheProvider();
      registerFallbackValue(Uri.parse('https://example.com'));
      registerFallbackValue(Uint8List(0));
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

      test('should return a rule for TikTok creator profile URLs', () {
        const url = 'https://www.tiktok.com/@scout2015';
        final rule = EmbedService.resolveRule(url);

        expect(rule, isNotNull);
        expect(rule?.providerName, equals('TikTok'));
      });

      test('should return null for unknown URLs', () {
        const url = 'https://example.com/unknown';
        final rule = EmbedService.resolveRule(url);

        expect(rule, isNull);
      });

      test('should use default rules when no config is provided', () {
        final rule =
            EmbedService.resolveRule('https://youtube.com/watch?v=123');
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('YouTube'));
      });

      test('should discover Tumblr as a verified provider by default', () {
        const url = 'https://www.tumblr.com/post/123';
        final rule = EmbedService.resolveRule(url);
        expect(rule, isNotNull);
        expect(rule?.providerName, equals('Tumblr'));
        expect(rule?.isVerified, isTrue);
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

        expect(iframeUrl, contains('youtube-nocookie.com/embed/dQw4w9WgXcQ'));
      });

      test('should suppress mode-mismatch logging during resolveRender', () {
        const url =
            'https://www.reddit.com/r/flutterdev/comments/17yv8y8/how_to_implement_embed_in_flutter/';
        final logs = <({String message, Map<String, dynamic>? data})>[];
        final logger = EmbedLogger.enabled(
          debugOnly: false,
          sink: ({
            required level,
            required message,
            data,
            error,
            stackTrace,
          }) {
            logs.add((message: message, data: data));
          },
        );
        final config = EmbedConfig(
          logger: logger,
          providers: const EmbedProviderConfig(
            providerRenderModes: {'Reddit': EmbedRenderMode.oembed},
          ),
        );

        final renderer = EmbedService.resolveRender(
          url,
          config: config,
          logger: logger,
          embedType: EmbedType.reddit,
        );

        expect(renderer, isA<OEmbedRenderer>());
        expect(
          logs.where((entry) => entry.message == 'Rendering mode mismatch'),
          isEmpty,
        );
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

      test('should use the cache provider from EmbedConfig', () async {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        final param = EmbedLoaderParam(
          url: url,
          embedType: EmbedType.youtube,
          width: 640,
        );
        final cachedResponse = {
          'version': '1.0',
          'type': 'video',
          'html': '<div>Cached YouTube Video</div>',
        };

        when(() => mockCacheProvider.getFileFromCache(any())).thenAnswer(
          (_) async => Uint8List.fromList(
            utf8.encode(jsonEncode(cachedResponse)),
          ),
        );

        final result = await EmbedService.getResult(
          param: param,
          config: EmbedConfig(cacheProvider: mockCacheProvider),
          httpClient: mockClient,
        );

        expect(result.html, equals('<div>Cached YouTube Video</div>'));
        verify(() => mockCacheProvider.getFileFromCache(any())).called(1);
        verifyNever(
            () => mockClient.get(any(), headers: any(named: 'headers')));
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
