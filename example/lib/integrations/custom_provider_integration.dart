import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class _CustomProviderSuggestion {
  final String label;
  final String url;

  const _CustomProviderSuggestion({required this.label, required this.url});
}

class _CustomProviderExample {
  final String title;
  final String providerName;
  final String description;
  final String notes;
  final String pattern;
  final String endpoint;
  final String inputLabel;
  final String inputHint;
  final List<_CustomProviderSuggestion> suggestions;

  const _CustomProviderExample({
    required this.title,
    required this.providerName,
    required this.description,
    required this.notes,
    required this.pattern,
    required this.endpoint,
    required this.inputLabel,
    required this.inputHint,
    required this.suggestions,
  });

  EmbedProviderRule get rule => EmbedProviderRule(
    providerName: providerName,
    pattern: pattern,
    endpoint: endpoint,
  );

  String get initialUrl => suggestions.first.url;

  String buildSampleCode() {
    return '''
EmbedScope(
  config: EmbedConfig(
    providers: EmbedProviderConfig(
      enabledProviders: {'$providerName'},
      customProviders: const [
        EmbedProviderRule(
          providerName: '$providerName',
          pattern: r'$pattern',
          endpoint: '$endpoint',
        ),
      ],
    ),
  ),
  child: EmbedCard.url('$initialUrl'),
)''';
  }
}

const List<_CustomProviderExample> _examples = [
  _CustomProviderExample(
    title: 'Pinterest',
    providerName: 'Pinterest',
    description:
        'Manual registration for Pinterest, including support for `pin.it` '
        'short links that are not covered by the built-in verified provider '
        'list.',
    notes:
        'Useful when you want deterministic Pinterest handling without '
        'depending on dynamic discovery.',
    pattern:
        r'^(https?:\/\/(?:www\.)?pinterest\.com\/.*|https?:\/\/pin\.it\/.*)$',
    endpoint: 'https://www.pinterest.com/oembed.json',
    inputLabel: 'Pinterest URL',
    inputHint: 'https://www.pinterest.com/pin/...',
    suggestions: [
      _CustomProviderSuggestion(
        label: 'Sample Pin',
        url: 'https://www.pinterest.com/pin/4574037118434475/',
      ),
      _CustomProviderSuggestion(
        label: 'Short Link',
        url: 'https://pin.it/2xjL4At7e',
      ),
    ],
  ),
  _CustomProviderExample(
    title: 'Bluesky',
    providerName: 'Bluesky Social',
    description:
        'Registering Bluesky explicitly. While Bluesky is in the bundled '
        'snapshot, you may want to register it manually to avoid enabling '
        'dynamic discovery globally.',
    notes: 'A modern social protocol with standard oEmbed support.',
    pattern: r'^https?:\/\/bsky\.app\/profile\/.*\/post\/.*',
    endpoint: 'https://embed.bsky.app/oembed',
    inputLabel: 'Bluesky URL',
    inputHint: 'https://bsky.app/profile/.../post/...',
    suggestions: [
      _CustomProviderSuggestion(
        label: 'Bluesky Post',
        url: 'https://bsky.app/profile/altnps.bsky.social/post/3mj6rcwjd2k23',
      ),
    ],
  ),
  _CustomProviderExample(
    title: 'audio.com',
    providerName: 'audio.com',
    description:
        'Registration for audio.com, showcasing how to support audio-focused '
        'providers from the bundled snapshot.',
    notes: 'Audio players typically have a fixed height.',
    pattern: r'^https?:\/\/audio\.com\/.*',
    endpoint: 'https://api.audio.com/oembed',
    inputLabel: 'audio.com URL',
    inputHint: 'https://audio.com/...',
    suggestions: [
      _CustomProviderSuggestion(
        label: 'Sample Track',
        url: 'https://audio.com/idnplay/audio/tirai77-dramatic-victory',
      ),
    ],
  ),
];

final Set<String> _exampleProviderNames =
    _examples.map((example) => example.providerName).toSet();

class CustomProviderIntegrationPage extends StatefulWidget {
  const CustomProviderIntegrationPage({super.key});

  @override
  State<CustomProviderIntegrationPage> createState() =>
      _CustomProviderIntegrationPageState();
}

class _CustomProviderIntegrationPageState
    extends State<CustomProviderIntegrationPage> {
  late _CustomProviderExample _selectedExample = _examples.first;
  late final TextEditingController _urlController = TextEditingController(
    text: _selectedExample.initialUrl,
  );
  late String _currentUrl = _selectedExample.initialUrl;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentConfig =
        EmbedScope.configOf(context, listen: false) ?? const EmbedConfig();
    final parentProviders = parentConfig.providers;
    final enabledProviders = parentProviders.enabledProviders;
    final inheritedCustomProviders =
        parentProviders.customProviders
            .where((rule) => !_exampleProviderNames.contains(rule.providerName))
            .toList();
    final customConfig = parentConfig.copyWith(
      providers: parentProviders.copyWith(
        enabledProviders:
            enabledProviders == null
                ? null
                : {...enabledProviders, _selectedExample.providerName},
        customProviders: [...inheritedCustomProviders, _selectedExample.rule],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Providers'),
        actions: const [ConfigMenuAction()],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manual Provider Registration',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'These examples show how to register a provider manually with '
              '`EmbedProviderConfig.customProviders`. Switch between recipes '
              'to see different patterns, endpoints, and sample URLs.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Provider Recipes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _examples
                      .map(
                        (example) => ChoiceChip(
                          label: Text(example.title),
                          selected: identical(example, _selectedExample),
                          onSelected: (_) => _selectExample(example),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedExample.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_selectedExample.description),
                  const SizedBox(height: 12),
                  Text(
                    _selectedExample.notes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Endpoint: ${_selectedExample.endpoint}\n'
                    'Pattern: ${_selectedExample.pattern}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SelectableText(
                _selectedExample.buildSampleCode(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _selectedExample.inputLabel,
                hintText: _selectedExample.inputHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: _applyUrl,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _applyUrl(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedExample.suggestions
                      .map(
                        (suggestion) => ActionChip(
                          label: Text(suggestion.label),
                          onPressed: () => _applySuggestion(suggestion.url),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Rendering:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            EmbedScope(
              config: customConfig,
              child: EmbedCard.url(
                _currentUrl,
                scrollable: _selectedExample.providerName == 'CodePen',
                key: ValueKey('${_selectedExample.providerName}:$_currentUrl'),
                style: const EmbedStyle(loadingBuilder: _buildPlaceholder),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPlaceholder(BuildContext context) {
    return const SocialEmbedPlaceholder(embedType: EmbedType.other);
  }

  void _applySuggestion(String url) {
    setState(() {
      _urlController.text = url;
      _currentUrl = url;
    });
  }

  void _applyUrl() {
    setState(() {
      _currentUrl = _urlController.text.trim();
    });
  }

  void _selectExample(_CustomProviderExample example) {
    setState(() {
      _selectedExample = example;
      _urlController.text = example.initialUrl;
      _currentUrl = example.initialUrl;
    });
  }
}
