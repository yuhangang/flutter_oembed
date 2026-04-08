import 'package:embed_example/utils/platform_utils.dart';
import 'package:embed_example/utils/settings_controller.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';

class DiscoveryIntegrationPage extends StatefulWidget {
  const DiscoveryIntegrationPage({super.key});

  @override
  State<DiscoveryIntegrationPage> createState() =>
      _DiscoveryIntegrationPageState();
}

class _DiscoveryIntegrationPageState extends State<DiscoveryIntegrationPage> {
  final TextEditingController _urlController = TextEditingController(
    text:
        'https://www.ted.com/talks/bill_gates_the_next_outbreak_we_re_not_ready',
  );
  String _currentUrl =
      'https://www.ted.com/talks/bill_gates_the_next_outbreak_we_re_not_ready';

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsProvider.of(context).settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Discovery'),
        actions: const [ConfigMenuAction()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dynamic OEmbed Discovery',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This page demonstrates the "Dynamic Discovery" feature. '
              'It uses the bundled OEmbed registry snapshot to find provider endpoints '
              'for URLs that are not explicitly handled by the library.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter OEmbed URL',
                hintText: 'e.g., https://www.ted.com/talks/...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () {
                    setState(() {
                      _currentUrl = _urlController.text.trim();
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (val) {
                setState(() {
                  _currentUrl = val.trim();
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildSuggestChip(
                  'TED',
                  'https://www.ted.com/talks/bill_gates_the_next_outbreak_we_re_not_ready',
                ),
                _buildSuggestChip(
                  'Tumblr',
                  'https://photobeppucity.tumblr.com/post/182232283903/0273-%E5%86%85%E6%88%90%E3%81%AE%E6%A3%9A%E7%94%B0-%E3%83%95%E3%83%ABhd25mb-%E5%8E%9F%E5%AF%B892mb',
                ),
                _buildSuggestChip(
                  'NYTimes',
                  'https://www.nytimes.com/2026/04/06/world/middleeast/iran-trump-deadline.html',
                ),
                _buildSuggestChip(
                  'Flickr',
                  'https://www.flickr.com/photos/nasahqphoto/55186319833/in/explore-2026-04-05/',
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_currentUrl.isNotEmpty) ...[
              Text(
                'Rendering:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // We wrap this inside an EmbedScope to enable discovery for this specific page
              // OR we can pass it via config in EmbedCard if it was supported (it's not, it uses Scope).
              EmbedScope(
                config: settings.toEmbedConfig().copyWith(
                  useDynamicDiscovery: true,
                ),
                child: EmbedCard.url(
                  _currentUrl,
                  key: ValueKey(_currentUrl),
                  style: EmbedStyle(
                    loadingBuilder:
                        (context) => SocialEmbedPlaceholder(
                          embedType:
                              getEmbedTypeFromUrl(_currentUrl) ??
                              EmbedType.other,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestChip(String label, String url) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _urlController.text = url;
          _currentUrl = url;
        });
      },
    );
  }
}
