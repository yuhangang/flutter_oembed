import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';
import 'package:flutter_html/flutter_html.dart';

String? _extractEmbedUrlFromHtml(ExtensionContext context) {
  final attributes = context.attributes;
  final candidates = <String?>[
    attributes['url'],
    attributes['href'],
    attributes['src'],
    attributes['data-url'],
    context.innerHtml.trim(),
  ];

  for (final candidate in candidates) {
    if (_isValidHttpUrl(candidate)) return candidate!.trim();
  }

  final urlInText = RegExp(
    "https?://[^\\s<>\"']+",
  ).firstMatch(context.innerHtml)?.group(0);
  if (_isValidHttpUrl(urlInText)) return urlInText!.trim();
  return null;
}

bool _isValidHttpUrl(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

class EmbedExtension extends HtmlExtension {
  @override
  Set<String> get supportedTags => {"oembed", "a"};

  @override
  bool matches(ExtensionContext context) {
    if (context.elementName == "oembed") return true;
    if (context.elementName == "a") {
      final title = context.attributes['title'] ?? '';
      final url = context.attributes['href'] ?? '';
      return title.toLowerCase() == 'embed' && _isValidHttpUrl(url);
    }
    return false;
  }

  @override
  InlineSpan build(ExtensionContext context) {
    final url =
        context.elementName == "oembed"
            ? _extractEmbedUrlFromHtml(context)
            : context.attributes['href'];

    if (url == null) return const TextSpan(text: "");

    return WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: EmbedCard.url(
          url,
          tracking: EmbedTracking(
            pageIdentifier: 'html_page',
            source: 'html',
            contentId: 'html_content_${url.hashCode}',
            elementId: 'html_element_${url.hashCode}',
          ),
        ),
      ),
    );
  }
}

class HtmlIntegrationPage extends StatefulWidget {
  const HtmlIntegrationPage({super.key});

  @override
  State<HtmlIntegrationPage> createState() => _HtmlIntegrationPageState();
}

class _HtmlIntegrationPageState extends State<HtmlIntegrationPage> {
  String _locale = 'en';
  Brightness _brightness = Brightness.light;
  bool _scrollable = false;
  bool _showFooter = false;

  @override
  Widget build(BuildContext context) {
    const htmlData = '''
<h1>HTML Integration Example</h1>
<p>This example demonstrates how to use the <code>oembed</code> package within <code>flutter_html</code>.</p>

<h3>Twitter Embed</h3>
<oembed url="https://twitter.com/X/status/1328842765115920384"></oembed>

<h3>YouTube Embed</h3>
<oembed>https://www.youtube.com/watch?v=dQw4w9WgXcQ</oembed>

<h3>Spotify Embed (via Link Title)</h3>
<p>You can also use a regular link with <code>title="embed"</code>:</p>
<a href="https://open.spotify.com/track/4cOdK2wGvV9m9X7S7O0WhS" title="embed">Spotify Track</a>

<h3>TikTok Embed</h3>
<oembed data-url="https://www.tiktok.com/@scout2015/video/6718335390845095173" />

<p>The <code>&lt;oembed&gt;</code> tag and <code>title="embed"</code> attribute are mapped to <code>EmbedCard</code> using a custom <code>HtmlExtension</code>. URL can come from <code>url</code>, <code>href</code>, <code>src</code>, <code>data-url</code>, or inner text.</p>
''';

    return EmbedScope(
      config:
          EmbedScope.configOf(
            context,
          )?.copyWith(locale: _locale, brightness: _brightness) ??
          EmbedConfig(locale: _locale, brightness: _brightness),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HTML Integration'),
          actions: [
            ConfigMenuAction(
              currentLocale: _locale,
              currentBrightness: _brightness,
              currentScrollable: _scrollable,
              currentShowFooter: _showFooter,
              onChanged: (locale, brightness, scrollable, showFooter) {
                setState(() {
                  _locale = locale;
                  _brightness = brightness;
                  _scrollable = scrollable;
                  _showFooter = showFooter;
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Html(
            key: ValueKey('html_$_locale-$_brightness'),
            data: htmlData,
            extensions: [EmbedExtension()],
          ),
        ),
      ),
    );
  }
}
