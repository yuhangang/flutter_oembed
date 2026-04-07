import 'package:flutter_embed/src/models/provider_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedProviderRule', () {
    test('resolveEndpoint with subRules', () {
      const rule = EmbedProviderRule(
        pattern: r'https://example\.com/.*',
        endpoint: 'https://example.com/api/default',
        providerName: 'Example',
        subRules: [
          EmbedSubRule(pattern: r'.*/video/.*', endpoint: 'https://example.com/api/video'),
          EmbedSubRule(pattern: r'.*/post/.*', endpoint: 'https://example.com/api/post'),
        ],
      );

      expect(rule.resolveEndpoint('https://example.com/video/1'), equals('https://example.com/api/video'));
      expect(rule.resolveEndpoint('https://example.com/post/1'), equals('https://example.com/api/post'));
      expect(rule.resolveEndpoint('https://example.com/other/1'), equals('https://example.com/api/default'));
    });

    test('matches uses regex', () {
      const rule = EmbedProviderRule(
        pattern: r'https://example\.com/.*',
        endpoint: 'https://example.com/api',
        providerName: 'Example',
      );

      expect(rule.matches('https://example.com/test'), isTrue);
      expect(rule.matches('https://google.com'), isFalse);
    });
  });

  group('EmbedSubRule', () {
    test('matches', () {
      const subRule = EmbedSubRule(pattern: r'.*/video/.*', endpoint: 'api');
      expect(subRule.matches('https://example.com/video/1'), isTrue);
      expect(subRule.matches('https://example.com/post/1'), isFalse);
    });
  });
}
