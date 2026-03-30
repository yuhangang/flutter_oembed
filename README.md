# flutter_oembed

A powerful, easy-to-use Flutter package for embedding social media content and other rich media using the OEmbed protocol.

## Features

- **Multi-provider Support:** X (Twitter), TikTok, Instagram, Facebook, YouTube, Spotify, Vimeo, and more.
- **Dynamic Sizing:** Automatically adjusts height to fit embedded content.
- **Smart Caching:** Built-in caching for OEmbed responses to improve performance and respect rate limits.
- **Iframe Optimization:** Direct iframe rendering support for YouTube and Spotify to skip API round-trips.
- **Privacy & Security:** Securely handles authentication tokens and implements Content Security Policy (CSP).
- **Extensible:** Easily add custom providers and render rules.

## Getting started

Add `oembed` to your `pubspec.yaml`:

```yaml
dependencies:
  oembed: ^0.0.1
```

## Usage

### Basic Usage

Wrap your app in an `OembedScope` to provide global configuration:

```dart
OembedScope(
  config: OembedConfig(
    facebookAppId: 'YOUR_APP_ID',
    facebookClientToken: 'YOUR_CLIENT_TOKEN',
  ),
  child: MyApp(),
)
```

Then use the `EmbedCard` widget anywhere in your app:

```dart
EmbedCard(
  url: 'https://twitter.com/X/status/1328842765115920384',
  embedType: EmbedType.x,
  embedContentType: EmbedContentType.richNewsStack,
  pageIdentifier: 'home_page',
  source: 'twitter',
  contentId: '1328842765115920384',
  elementId: 'tweet_1',
  extraIdentifier: '',
)
```

### Advanced Configuration

You can customize caching, render modes, and styles:

```dart
OembedConfig(
  providers: OembedProviderConfig(
    providerRenderModes: {
      'YouTube': OembedRenderMode.iframe,
      'Spotify': OembedRenderMode.iframe,
    },
  ),
  cache: OembedCacheConfig(
    enabled: true,
    defaultCacheDuration: Duration(days: 7),
  ),
  style: OembedStyle(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### Debug Logging

Enable debug logging when you want to trace provider resolution, cache hits,
network requests, and WebView loading events:

```dart
OembedConfig(
  logger: const OembedLogger.debug(),
)
```

You can also forward logs to your own logger:

```dart
OembedConfig(
  onLinkTap: (url, data) {
    debugPrint('Clicked $url on $data');
  },
  logger: OembedLogger.enabled(
    level: OembedLogLevel.info,
    sink: ({
      required OembedLogLevel level,
      required String message,
      Object? error,
      StackTrace? stackTrace,
    }) {
      myLogger.log(
        message,
        level: level.name,
        error: error,
        stackTrace: stackTrace,
      );
    },
  ),
)
```

### Markdown Integration (`markdown_widget`)

`markdown_widget` does not parse HTML tags by default, so add a custom block
syntax for `<oembed>` and a tag generator:

```dart
class OembedBlockSyntax extends md.BlockSyntax {
  const OembedBlockSyntax();

  @override
  RegExp get pattern => RegExp(
        r'^\s*<oembed\b[^>]*>(?:.*</oembed>\s*)?$|^\s*<oembed\b[^>]*/>\s*$',
        caseSensitive: false,
      );

  @override
  md.Node? parse(md.BlockParser parser) {
    final raw = parser.current.content.trim();
    parser.advance();
    final url = RegExp(r'\burl\s*=\s*"([^"]+)"', caseSensitive: false)
            .firstMatch(raw)
            ?.group(1) ??
        RegExp(r'<oembed\b[^>]*>([\s\S]*?)</oembed>', caseSensitive: false)
            .firstMatch(raw)
            ?.group(1)
            ?.trim();
    if (url == null || url.isEmpty) return md.Text(raw);
    final element = md.Element('oembed', [md.Text(url)]);
    element.attributes['url'] = url;
    return element;
  }
}

MarkdownWidget(
  data: content,
  markdownGenerator: MarkdownGenerator(
    blockSyntaxList: const [OembedBlockSyntax()],
    generators: [
      SpanNodeGeneratorWithTag(
        tag: 'oembed',
        generator: (e, config, visitor) => OembedNode(
          e.attributes['url'] ?? e.textContent,
        ),
      ),
    ],
  ),
)

class OembedNode extends SpanNode {
  final String url;
  OembedNode(this.url);

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: EmbedCard(
        url: url,
        embedContentType: EmbedContentType.newsReaderMode,
        pageIdentifier: 'markdown_page',
        source: 'markdown',
        contentId: 'markdown_content_${url.hashCode}',
        elementId: 'markdown_element_${url.hashCode}',
        extraIdentifier: '',
      ),
    );
  }
}
```

### HTML Integration (`flutter_html`)

Use a `TagExtension` and extract URL from `url`, `href`, `src`, `data-url`, or
inner text:

```dart
String? extractOembedUrl(ExtensionContext context) {
  final attrs = context.attributes;
  final candidates = [
    attrs['url'],
    attrs['href'],
    attrs['src'],
    attrs['data-url'],
    context.innerHtml.trim(),
  ];
  for (final c in candidates) {
    final uri = Uri.tryParse(c ?? '');
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return c!.trim();
    }
  }
  return null;
}

Html(
  data: htmlContent,
  extensions: [
    TagExtension(
      tagsToExtend: {"oembed"},
      builder: (context) {
        final url = extractOembedUrl(context);
        if (url == null) return const SizedBox.shrink();
        return EmbedCard(
          url: url,
          embedContentType: EmbedContentType.newsReaderMode,
          pageIdentifier: 'html_page',
          source: 'html',
          contentId: 'html_content_${url.hashCode}',
          elementId: 'html_element_${url.hashCode}',
          extraIdentifier: '',
        );
      },
    ),
  ],
)
```

## Additional information

For more examples, check the `/example` folder in the repository.
