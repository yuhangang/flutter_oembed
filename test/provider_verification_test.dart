import 'package:flutter_oembed/src/models/configs/embed_provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedProviders Verification', () {
    test('EmbedProviders.verified filters out unverified providers by default',
        () {
      final providers = EmbedProviders.verified;

      // Check that known unverified providers like TED are not in the list
      final ted = providers.any((p) => p.providerName == 'TED');
      expect(ted, isFalse);

      // Check that known verified providers like YouTube are in the list
      final youtube = providers.any((p) => p.providerName == 'YouTube');
      expect(youtube, isTrue);
    });

    test(
      'EmbedProviders.all includes unverified providers',
      () {
        final providers = EmbedProviders.all;

        // TED should be included now
        final ted = providers.any((p) => p.providerName == 'TED');
        expect(ted, isTrue);
      },
    );

    test(
      'EmbedProviders config defaults to verified if null',
      () {
        const config = EmbedProviderConfig();
        final isEnabled = config.isEnabled('YouTube');
        final isNotEnabled = config.isEnabled('TED');

        expect(isEnabled, isTrue);
        expect(isNotEnabled, isFalse);
      },
    );
  });
}
