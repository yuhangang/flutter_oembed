import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
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

  group('EmbedConstraints', () {
    test('clampHeight applies min and max bounds', () {
      const constraints = EmbedConstraints(minHeight: 120, maxHeight: 240);

      expect(constraints.clampHeight(80), equals(120));
      expect(constraints.clampHeight(180), equals(180));
      expect(constraints.clampHeight(400), equals(240));
    });

    test('copyWith preserves unspecified values', () {
      const constraints = EmbedConstraints(
        preferredHeight: 152,
        minHeight: 120,
      );

      final updated = constraints.copyWith(maxHeight: 300);

      expect(updated.preferredHeight, equals(152));
      expect(updated.minHeight, equals(120));
      expect(updated.maxHeight, equals(300));
    });

    test('copyWith can explicitly clear fields', () {
      const constraints = EmbedConstraints(
        preferredHeight: 232,
        minHeight: 180,
        maxHeight: 320,
      );

      final updated = constraints.copyWith(
        preferredHeight: null,
        minHeight: null,
      );

      expect(updated.preferredHeight, isNull);
      expect(updated.minHeight, isNull);
      expect(updated.maxHeight, equals(320));
    });

    test('rejects negative preferredHeight', () {
      expect(
        () => EmbedConstraints(preferredHeight: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
