import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_provider_config.dart';
import 'package:flutter_embed/src/services/embed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderRegistry Spotify Extra', () {
    const config = EmbedConfig(
      providers: EmbedProviderConfig(
        providerRenderModes: {
          'Spotify': EmbedRenderMode.iframe,
        },
      ),
    );

    test('Spotify iframe builder with too few segments', () {
      final url = EmbedService.resolveIframeUrl('https://open.spotify.com/',
          config: config);
      expect(url, isNull);
    });
  });
}
