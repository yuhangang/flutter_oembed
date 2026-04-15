import 'package:embed_example/utils/platform_utils.dart';
import 'package:embed_example/utils/settings_controller.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

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
  EmbedExtension({this.controllerForUrl});

  final EmbedController? Function(String url)? controllerForUrl;

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

    final settings = ExampleSettingsProvider.of(context.buildContext!).settings;

    return WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: EmbedCard.url(
          url,
          controller: controllerForUrl?.call(url),
          scrollable: settings.scrollable,
          lazyLoad: true,
          style: EmbedStyle(
            loadingBuilder:
                (context) => SocialEmbedPlaceholder(
                  embedType: getEmbedTypeFromUrl(url) ?? EmbedType.other,
                ),
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
  bool showBorder = true;
  final Map<String, EmbedController> _controllersByUrl = {};

  EmbedController _controllerForUrl(String url) {
    return _controllersByUrl.putIfAbsent(url, EmbedController.new);
  }

  EmbedConfig _buildScopedConfig(BuildContext context) {
    final settings = ExampleSettingsProvider.of(context).settings;
    final parentConfig = EmbedScope.configOf(context, listen: false);
    return (parentConfig ?? const EmbedConfig()).copyWith(
      locale: settings.locale,
      brightness: settings.brightness,
      scrollable: settings.scrollable,
      useDynamicDiscovery: settings.useDynamicDiscovery,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllersByUrl.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsProvider.of(context).settings;
    const htmlData = '''
<h1>HTML Integration Example</h1>
<p>This example demonstrates how to use the <code>oembed</code> package within <code>flutter_html</code>.</p>

<h3>Twitter Embed</h3>
<div class="embed-card">
  <oembed url="https://twitter.com/X/status/1328842765115920384"></oembed>
</div>

<h3>YouTube Embed</h3>
<div class="embed-card">
  <oembed>https://www.youtube.com/watch?v=dQw4w9WgXcQ</oembed>
</div>

<h3>TikTok Embed</h3>
<div class="embed-card">
  <oembed data-url="https://www.tiktok.com/@scout2015/video/6718335390845095173" />
</div>

<h3>GIPHY Embed</h3>
<div class="embed-card">
  <oembed url="https://giphy.com/gifs/moodman-monkey-side-eye-sideeye-H5C8CevNMbpBqNqFjl"></oembed>
</div>

<p>The <code>&lt;oembed&gt;</code> tag and <code>title="embed"</code> attribute are mapped to <code>EmbedCard</code> using a custom <code>HtmlExtension</code>. URL can come from <code>url</code>, <code>href</code>, <code>src</code>, <code>data-url</code>, or inner text.</p>
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Integration'),
        actions: const [ConfigMenuAction()],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: SwitchListTile(
            title: const Text('Show Border'),
            value: showBorder,
            onChanged: (value) {
              setState(() {
                showBorder = value;
              });
            },
          ),
        ),
      ),
      body: EmbedScope(
        config: _buildScopedConfig(context),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Html(
            key: ValueKey('html_${settings.locale}-${settings.brightness}'),
            data: htmlData,
            extensions: [EmbedExtension(controllerForUrl: _controllerForUrl)],
            style:
                showBorder
                    ? {
                      ".embed-card": Style(
                        margin: Margins.only(top: 8, bottom: 24),
                        padding: HtmlPaddings.all(12),
                        backgroundColor: Theme.of(context).canvasColor,

                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    }
                    : {},
          ),
        ),
      ),
    );
  }
}
