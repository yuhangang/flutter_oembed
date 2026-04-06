import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_loader_param.dart';
import 'package:flutter_embed/src/models/embed_provider_config.dart';
import 'package:flutter_embed/src/services/embed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedService', () {
    test('resolveRule matches YouTube URL', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final rule = EmbedService.resolveRule(url);

      expect(rule, isNotNull);
      expect(rule?.providerName, equals('YouTube'));
    });

    test('resolveRule matches TikTok URL', () {
      const url = 'https://www.tiktok.com/@scout2015/video/6771039285231176966';
      final rule = EmbedService.resolveRule(url);

      expect(rule, isNotNull);
      expect(rule?.providerName, equals('TikTok'));
    });

    test('resolveRule returns null for unknown URL', () {
      const url = 'https://example.com/unknown';
      final rule = EmbedService.resolveRule(url);

      expect(rule, isNull);
    });

    test('resolveIframeUrl returns correct URL for YouTube', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      const config = EmbedConfig(
        providers: EmbedProviderConfig(
          providerRenderModes: {'YouTube': EmbedRenderMode.iframe},
        ),
      );

      final iframeUrl = EmbedService.resolveIframeUrl(url, config: config);

      expect(iframeUrl, contains('youtube.com/embed/dQw4w9WgXcQ'));
    });

    test('resolveIframeUrl returns null if render mode is not iframe', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      const config = EmbedConfig(
        providers: EmbedProviderConfig(
          providerRenderModes: {'YouTube': EmbedRenderMode.oembed},
        ),
      );

      final iframeUrl = EmbedService.resolveIframeUrl(url, config: config);

      expect(iframeUrl, isNull);
    });

    test('getEmbedApiByEmbedType returns GenericEmbedApi for unknown URL', () {
      const url = 'https://example.com/unknown';
      final param = EmbedLoaderParam(
        url: url,
        embedType: EmbedType.other,
        width: 640,
      );
      final api = EmbedService.getEmbedApiByEmbedType(param);

      expect(api.baseUrl, equals(url));
    });
  });
}
