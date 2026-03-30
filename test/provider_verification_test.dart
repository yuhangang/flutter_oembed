import 'package:flutter_test/flutter_test.dart';
import 'package:oembed/src/models/oembed_provider_config.dart';
import 'package:oembed/src/models/provider_rule.dart';

void main() {
  group('OembedProviderConfig Verification', () {
    test('effectiveProviders filters out unverified providers by default', () {
      const config = OembedProviderConfig();
      final providers = config.effectiveProviders;

      // Check that known unverified providers like Reddit are not in the list
      final reddit = providers.any((p) => p.providerName == 'Reddit');
      expect(reddit, isFalse);

      // Check that known verified providers like YouTube are in the list
      final youtube = providers.any((p) => p.providerName == 'YouTube');
      expect(youtube, isTrue);
    });

    test(
      'effectiveProviders includes unverified providers when includeUnverified is true',
      () {
        const config = OembedProviderConfig(includeUnverified: true);
        final providers = config.effectiveProviders;

        // Reddit should be included now
        final reddit = providers.any((p) => p.providerName == 'Reddit');
        expect(reddit, isTrue);
      },
    );

    test(
      'effectiveProviders includes custom providers regardless of verification',
      () {
        final customRule = const OembedProviderRule(
          pattern: 'custom',
          endpoint: 'custom',
          providerName: 'Custom',
        );
        final config = OembedProviderConfig(customProviders: [customRule]);
        final providers = config.effectiveProviders;

        final custom = providers.any((p) => p.providerName == 'Custom');
        expect(custom, isTrue);
      },
    );
  });
}
