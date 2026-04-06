import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/models/embed_provider_config.dart';
import 'package:flutter_embed/src/models/provider_rule.dart';

void main() {
  group('EmbedProviderConfig Verification', () {
    test('effectiveProviders filters out unverified providers by default', () {
      const config = EmbedProviderConfig();
      final providers = config.effectiveProviders;

      // Check that known unverified providers like TED are not in the list
      final ted = providers.any((p) => p.providerName == 'TED');
      expect(ted, isFalse);

      // Check that known verified providers like YouTube are in the list
      final youtube = providers.any((p) => p.providerName == 'YouTube');
      expect(youtube, isTrue);
    });

    test(
      'effectiveProviders includes unverified providers when includeUnverified is true',
      () {
        const config = EmbedProviderConfig(includeUnverified: true);
        final providers = config.effectiveProviders;

        // TED should be included now
        final ted = providers.any((p) => p.providerName == 'TED');
        expect(ted, isTrue);
      },
    );

    test(
      'effectiveProviders includes custom providers regardless of verification',
      () {
        final customRule = const EmbedProviderRule(
          pattern: 'custom',
          endpoint: 'custom',
          providerName: 'Custom',
        );
        final config = EmbedProviderConfig(customProviders: [customRule]);
        final providers = config.effectiveProviders;

        final custom = providers.any((p) => p.providerName == 'Custom');
        expect(custom, isTrue);
      },
    );
  });
}
