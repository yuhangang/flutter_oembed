import 'dart:convert';

import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';

String buildEmbedWebSrcDoc({
  required EmbedData data,
  required EmbedProviderStrategy strategy,
  required EmbedType type,
  required double maxWidth,
  required bool scrollable,
}) {
  final document = strategy.buildHtmlDocument(
    data.html,
    type: type,
    maxWidth: maxWidth,
    scrollable: scrollable,
  );
  final baseUrl = strategy.resolveBaseUrl(data);
  final documentWithBase = injectBaseHrefIntoHtmlDocument(document, baseUrl);

  // Inject a channel polyfill for web to bridge the gap between internal
  // messenger scripts that expect mobile channels and the web postMessage host.
  const channelPolyfill = '''
<script>
  (function() {
    if (window.parent && window.parent !== window) {
      const bridge = (type, message) => {
        window.parent.postMessage(JSON.stringify({ type, payload: message }), '*');
      };
      if (!window.HeightChannel) {
        window.HeightChannel = { postMessage: (msg) => bridge('height', msg) };
      }
      if (!window.ErrorChannel) {
        window.ErrorChannel = { postMessage: (msg) => bridge('error', msg) };
      }
    }
  })();
</script>
''';

  final headTagPattern = RegExp(r'<head[^>]*>', caseSensitive: false);
  final headMatch = headTagPattern.firstMatch(documentWithBase);
  if (headMatch != null) {
    final insertOffset = headMatch.end;
    return documentWithBase.replaceRange(
      insertOffset,
      insertOffset,
      channelPolyfill,
    );
  }

  return channelPolyfill + documentWithBase;
}

String injectBaseHrefIntoHtmlDocument(String html, String? baseUrl) {
  if (baseUrl == null || baseUrl.isEmpty) {
    return html;
  }

  final hasBaseTag = RegExp(r'<base\s', caseSensitive: false).hasMatch(html);
  if (hasBaseTag) {
    return html;
  }

  final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  final baseTag = '<base href="${htmlEscape.convert(normalizedBaseUrl)}">';
  final headTagPattern = RegExp(r'<head[^>]*>', caseSensitive: false);
  final headMatch = headTagPattern.firstMatch(html);
  if (headMatch != null) {
    final insertOffset = headMatch.end;
    return html.replaceRange(insertOffset, insertOffset, baseTag);
  }

  final htmlTagPattern = RegExp(r'<html[^>]*>', caseSensitive: false);
  final htmlMatch = htmlTagPattern.firstMatch(html);
  if (htmlMatch != null) {
    final insertOffset = htmlMatch.end;
    return html.replaceRange(
        insertOffset, insertOffset, '<head>$baseTag</head>');
  }

  return '<head>$baseTag</head>$html';
}
