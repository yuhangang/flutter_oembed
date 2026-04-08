import 'package:flutter_oembed/src/services/providers_snapshot_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProvidersSnapshotGenerator', () {
    const fixture = '''
[
  {
    "provider_name": "Example",
    "endpoints": [
      {
        "schemes": [
          "https://example.com/posts/*",
          "https://example.com/posts/*"
        ],
        "url": "https://example.com/oembed"
      },
      {
        "schemes": [
          "https://*.example.com/posts/*"
        ],
        "url": "https://example.com/oembed"
      }
    ]
  },
  {
    "provider_name": "Ignored",
    "endpoints": [
      {
        "url": "https://ignored.example/oembed"
      }
    ]
  }
]
''';

    test('buildProvidersSnapshotIndex groups and deduplicates rules', () {
      final index = buildProvidersSnapshotIndex([
        {
          'provider_name': 'Example',
          'endpoints': [
            {
              'schemes': [
                'https://example.com/posts/*',
                'https://example.com/posts/*',
              ],
              'url': 'https://example.com/oembed',
            },
            {
              'schemes': ['https://*.example.com/posts/*'],
              'url': 'https://example.com/oembed',
            },
          ],
        },
      ]);

      expect(index.keys, containsAll(['example.com', '*.example.com']));
      expect(index['example.com'], hasLength(1));
      expect(index['*.example.com'], hasLength(1));
      expect(index['example.com']!.single.providerName, 'Example');
    });

    test('generateProvidersSnapshotSource emits stable Dart source', () {
      final output = generateProvidersSnapshotSource(
        fixture,
        sourceUrl: 'https://fixture.test/providers.json',
      );

      expect(output, contains('// Source: https://fixture.test/providers.json'));
      expect(output,
          contains('const Map<String, List<EmbedProviderRule>> kEmbedProvidersSnapshot = {'));
      expect(output, contains('"*.example.com": ['));
      expect(output, contains('"example.com": ['));
      expect(
        RegExp(r'"providerName":').hasMatch(output),
        isFalse,
      );
      expect(
        'providerName: "Example"'.allMatches(output).length,
        2,
      );
      expect(
        'pattern: "^https?:\\\\/\\\\/example\\\\.com\\\\/posts\\\\/.*"'
            .allMatches(output)
            .length,
        1,
      );
    });
  });
}
