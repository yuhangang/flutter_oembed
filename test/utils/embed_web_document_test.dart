import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/utils/embed_web_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('injectBaseHrefIntoHtmlDocument', () {
    test('injects base tag into existing head', () {
      final html = '<html><head><title>Test</title></head><body></body></html>';

      final result = injectBaseHrefIntoHtmlDocument(
        html,
        'https://example.com/embed',
      );

      expect(
        result,
        contains('<base href="https:&#47;&#47;example.com&#47;embed&#47;">'),
      );
    });

    test('does not duplicate existing base tag', () {
      final html =
          '<html><head><base href="https://old.example/"></head></html>';

      final result = injectBaseHrefIntoHtmlDocument(
        html,
        'https://example.com/embed',
      );

      expect(RegExp(r'<base\s', caseSensitive: false).allMatches(result),
          hasLength(1));
      expect(result, contains('https://old.example/'));
    });
  });

  test('buildEmbedWebSrcDoc uses provider html builder and base url', () {
    const data = EmbedData(
      html: '<blockquote>embed</blockquote>',
      providerUrl: 'https://provider.example',
    );

    final result = buildEmbedWebSrcDoc(
      data: data,
      strategy: const GenericEmbedProviderStrategy(),
      type: EmbedType.other,
      maxWidth: 640,
      scrollable: false,
    );

    expect(
      result,
      contains('<base href="https:&#47;&#47;provider.example&#47;">'),
    );
    expect(result, contains('<blockquote>embed</blockquote>'));
  });
}
