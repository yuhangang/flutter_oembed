import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';
import 'package:flutter_oembed/src/models/embed_provider_config.dart';
import 'package:flutter_oembed/src/models/embed_strings.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedProviderConfig', () {
    test('isEnabled', () {
      const config = EmbedProviderConfig(enabledProviders: {'YouTube'});
      expect(config.isEnabled('YouTube'), isTrue);
      expect(config.isEnabled('Vimeo'), isFalse);

      const configAll = EmbedProviderConfig();
      expect(configAll.isEnabled('Vimeo'), isTrue);
    });

    test('getRenderMode', () {
      const config = EmbedProviderConfig(
        providerRenderModes: {'YouTube': EmbedRenderMode.iframe},
      );
      expect(config.getRenderMode('YouTube'), equals(EmbedRenderMode.iframe));
      expect(config.getRenderMode('Vimeo'), equals(EmbedRenderMode.oembed));
    });

    test('copyWith', () {
      const config = EmbedProviderConfig();
      final updated = config.copyWith(enabledProviders: {'YouTube'});
      expect(updated.enabledProviders, contains('YouTube'));
    });

    test('effectiveProviders filtering', () {
      const config = EmbedProviderConfig(
        includeUnverified: true,
        enabledProviders: {'YouTube', 'Vimeo'},
      );
      final providers = config.effectiveProviders;
      expect(
          providers.every(
              (p) => p.providerName == 'YouTube' || p.providerName == 'Vimeo'),
          isTrue);
    });
  });

  group('EmbedConfig', () {
    test('resolvedProviders syncs discovery flag', () {
      const config = EmbedConfig(useDynamicDiscovery: true);
      expect(config.resolvedProviders.useDynamicDiscovery, isTrue);
    });

    test('copyWith', () {
      const config = EmbedConfig();
      final updated = config.copyWith(
        facebookAppId: 'new',
        strings: const EmbedStrings(
          loadingSemanticsLabel: 'Memuat kandungan',
        ),
      );
      expect(updated.facebookAppId, equals('new'));
      expect(
        updated.strings.loadingSemanticsLabel,
        equals('Memuat kandungan'),
      );
    });

    test('defaults use shared embed constants', () {
      const config = EmbedConfig();
      const style = EmbedStyle();

      expect(config.loadTimeout, equals(kDefaultEmbedLoadTimeout));
      expect(
        style.maxScrollableHeight,
        equals(kDefaultMaxScrollableEmbedHeight),
      );
    });
  });
}
