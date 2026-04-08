import 'package:embed_example/utils/platform_utils.dart';
import 'package:embed_example/utils/settings_controller.dart';
import 'package:embed_example/utils/url_launcher_utils.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';

class EmbedBlockSyntax extends md.BlockSyntax {
  const EmbedBlockSyntax();

  static final RegExp _tagPattern = RegExp(
    r'^\s*<oembed\b[^>]*>(?:.*</oembed>\s*)?$|^\s*<oembed\b[^>]*/>\s*$',
    caseSensitive: false,
  );

  @override
  RegExp get pattern => _tagPattern;

  @override
  md.Node? parse(md.BlockParser parser) {
    final raw = parser.current.content.trim();
    parser.advance();

    final url = _extractEmbedUrl(raw);
    if (url == null) {
      return md.Text(raw);
    }

    final element = md.Element('oembed', [md.Text(url)]);
    element.attributes['url'] = url;
    return element;
  }
}

String? _extractEmbedUrl(String rawTag) {
  final attributePatterns = <RegExp>[
    RegExp(r'\burl\s*=\s*"([^"]+)"', caseSensitive: false),
    RegExp(r"\burl\s*=\s*'([^']+)'", caseSensitive: false),
    RegExp(r'\bhref\s*=\s*"([^"]+)"', caseSensitive: false),
    RegExp(r"\bhref\s*=\s*'([^']+)'", caseSensitive: false),
    RegExp(r'\bsrc\s*=\s*"([^"]+)"', caseSensitive: false),
    RegExp(r"\bsrc\s*=\s*'([^']+)'", caseSensitive: false),
    RegExp(r'\bdata-url\s*=\s*"([^"]+)"', caseSensitive: false),
    RegExp(r"\bdata-url\s*=\s*'([^']+)'", caseSensitive: false),
  ];

  for (final pattern in attributePatterns) {
    final match = pattern.firstMatch(rawTag);
    if (match != null) {
      final candidate = match.group(1)?.trim();
      if (_isValidHttpUrl(candidate)) return candidate;
    }
  }

  final innerTextMatch = RegExp(
    r'<oembed\b[^>]*>([\s\S]*?)</oembed>',
    caseSensitive: false,
  ).firstMatch(rawTag);

  final innerText = innerTextMatch?.group(1)?.trim();
  if (_isValidHttpUrl(innerText)) return innerText;
  return null;
}

bool _isValidHttpUrl(String? value) {
  if (value == null || value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

class SmartLinkNode extends ElementNode {
  final Map<String, String> attributes;
  final LinkConfig linkConfig;

  SmartLinkNode(this.attributes, this.linkConfig);

  @override
  InlineSpan build() {
    final url = attributes['href'] ?? '';

    // Check if the link text is "embed" to trigger an embed instead of a link
    if (_isEmbedLink()) {
      return EmbedNode(url).build();
    }

    // Default to regular link
    return TextSpan(
      children: List.generate(
        children.length,
        (index) => _toLinkInlineSpan(
          children[index].build(),
          () => _onLinkTap(linkConfig, url),
        ),
      ),
    );
  }

  bool _isEmbedLink() {
    // Case 1: Title attribute is "embed" (e.g. [Link](url "embed"))
    if (attributes['title']?.toLowerCase() == 'embed') {
      return true;
    }

    // Case 2: Link text is "embed" (e.g. [embed](url))
    if (children.length == 1) {
      final child = children.first;
      if (child is TextNode) {
        return child.text.toLowerCase() == 'embed';
      }
    }

    return false;
  }

  void _onLinkTap(LinkConfig linkConfig, String url) {
    if (linkConfig.onTap != null) {
      linkConfig.onTap?.call(url);
    } else {
      openUrl(url);
    }
  }

  InlineSpan _toLinkInlineSpan(InlineSpan span, VoidCallback onTap) {
    if (span is TextSpan) {
      return TextSpan(
        text: span.text,
        children:
            span.children?.map((e) => _toLinkInlineSpan(e, onTap)).toList(),
        style: span.style,
        recognizer: TapGestureRecognizer()..onTap = onTap,
      );
    }
    return span;
  }
}

// Custom generator for smart links
final smartLinkGenerator = SpanNodeGeneratorWithTag(
  tag: MarkdownTag.a.name,
  generator: (element, config, visitor) {
    // Get the LinkConfig from the config object
    final linkConfig = config.a;
    return SmartLinkNode(element.attributes, linkConfig);
  },
);

// Custom generator for oembed tags
final oembedGenerator = SpanNodeGeneratorWithTag(
  tag: 'oembed',
  generator: (element, config, visitor) {
    final url = element.attributes['url'] ?? element.textContent;
    return EmbedNode(url);
  },
);

class MarkdownIntegrationPage extends StatefulWidget {
  const MarkdownIntegrationPage({super.key});

  @override
  State<MarkdownIntegrationPage> createState() =>
      _MarkdownIntegrationPageState();
}

class _MarkdownIntegrationPageState extends State<MarkdownIntegrationPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsProvider.of(context).settings;
    const markdownData = '''
# Markdown Integration Example

This example demonstrates how to use the `oembed` package within a `markdown_widget`.

## Twitter Embed
<oembed url="https://twitter.com/X/status/1328842765115920384"></oembed>

## YouTube Embed
<oembed>https://www.youtube.com/watch?v=dQw4w9WgXcQ</oembed>

## TikTok Embed
<oembed data-url="https://www.tiktok.com/@scout2015/video/6718335390845095173" />

## Spotify Embed (via Link Title)
[Spotify Track](https://open.spotify.com/track/4cOdK2wGvV9m9X7S7O0WhS "embed")

## Vimeo Embed (via Link Text)
[embed](https://vimeo.com/76979871)

## X (Twitter) Embed
<oembed>https://x.com/X/status/1328842765115920384</oembed>

## GIPHY Embed
<oembed url="https://giphy.com/gifs/moodman-monkey-side-eye-sideeye-H5C8CevNMbpBqNqFjl"></oembed>

You can add any OEmbed-supported URL using `url`, `href`, `src`, `data-url`, as inner text, or using the `[embed](url)` / `[title](url "embed")` link syntax.
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Integration'),
        actions: const [ConfigMenuAction()],
      ),
      body: MarkdownWidget(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        key: ValueKey('markdown_${settings.locale}-${settings.brightness}'),
        data: markdownData,
        config: MarkdownConfig(
            configs: [
              SmartLinkConfig(
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                onTap: (url) {},
              ),
            ],
          ),
          markdownGenerator: MarkdownGenerator(
            generators: [smartLinkGenerator, oembedGenerator],
            blockSyntaxList: const [EmbedBlockSyntax()],
            extensionSet: md.ExtensionSet.gitHubFlavored,
          ),
        ),
    );
  }
}

class EmbedNode extends SpanNode {
  final String url;

  EmbedNode(this.url);

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: KeepAliveEmbed(url: url),
      ),
    );
  }
}

class KeepAliveEmbed extends StatefulWidget {
  final String url;

  const KeepAliveEmbed({super.key, required this.url});

  @override
  State<KeepAliveEmbed> createState() => _KeepAliveEmbedState();
}

class _KeepAliveEmbedState extends State<KeepAliveEmbed>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = ExampleSettingsProvider.of(context).settings;

    return EmbedCard.url(
      widget.url,
      scrollable: settings.scrollable,
      style: EmbedStyle(
        loadingBuilder:
            (context) => SocialEmbedPlaceholder(
              embedType: getEmbedTypeFromUrl(widget.url) ?? EmbedType.other,
            ),
      ),
    );
  }
}

// Custom LinkConfig (optional, to use default just omit this)
class SmartLinkConfig extends LinkConfig {
  const SmartLinkConfig({
    super.style = const TextStyle(
      color: Color(0xff0969da),
      decoration: TextDecoration.underline,
    ),
    super.onTap,
  });
}
