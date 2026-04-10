import 'package:embed_example/utils/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:embed_example/widgets/config_menu_action.dart';

class YoutubePlayerIntegrationPage extends StatefulWidget {
  const YoutubePlayerIntegrationPage({super.key});

  @override
  State<YoutubePlayerIntegrationPage> createState() =>
      _YoutubePlayerIntegrationState();
}

class _YoutubePlayerIntegrationState
    extends State<YoutubePlayerIntegrationPage> {
  // A standard YouTube video url
  final _testUrl = 'https://www.youtube.com/watch?v=00BHXAzYRTA';
  // A YouTube Shorts url
  final _shortsUrl = 'https://www.youtube.com/shorts/nSDgHBxUbVQ';
  double _videoHeight = 220;
  double _shortsHeight = 520;

  @override
  Widget build(BuildContext context) {
    final controller = ExampleSettingsProvider.of(context);
    final settings = controller.settings;
    final youtubeParams = settings.youtubeParams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Native Player IFrame'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [ConfigMenuAction()],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simple YouTube Embed Player',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Note: This widget is intended for simple use cases only. If you need full control over the player state, custom overlays, or the YouTube IFrame Player API, we strongly recommend using community packages like youtube_player_iframe.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Show Controls'),
                          value: youtubeParams.controls ?? true,
                          onChanged:
                              (val) => controller.updateYoutube(
                                youtubeParams.copyWith(controls: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Autoplay'),
                          value: youtubeParams.autoplay ?? false,
                          onChanged:
                              (val) => controller.updateYoutube(
                                youtubeParams.copyWith(autoplay: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Loop'),
                          value: youtubeParams.loop ?? false,
                          onChanged:
                              (val) => controller.updateYoutube(
                                youtubeParams.copyWith(loop: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Show Related Videos (rel)'),
                          value: youtubeParams.rel ?? false,
                          onChanged:
                              (val) => controller.updateYoutube(
                                youtubeParams.copyWith(rel: val),
                              ),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeightControls(
                    context,
                    title: 'Landscape Player Height',
                    value: _videoHeight,
                    presets: const [180.0, 220.0, 280.0, 360.0],
                    min: 160,
                    max: 420,
                    onChanged: (value) {
                      setState(() => _videoHeight = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final effectiveWidth = width.isFinite ? width : 640.0;
                      return YoutubeEmbedPlayer(
                        // You must change the key so the WebView reloads the URL
                        // when options change
                        key: ValueKey(
                          '${youtubeParams.controls}-${youtubeParams.autoplay}-${youtubeParams.loop}-${youtubeParams.rel}-${youtubeParams.theme}-${youtubeParams.color}-${settings.locale}-${settings.brightness}-${_videoHeight.round()}',
                        ),
                        videoIdOrUrl: _testUrl,
                        controls: youtubeParams.controls ?? true,
                        autoplay: youtubeParams.autoplay ?? false,
                        loop: youtubeParams.loop ?? false,
                        rel: youtubeParams.rel ?? false,
                        theme: youtubeParams.theme,
                        color: youtubeParams.color,
                        maxWidth: effectiveWidth,
                        aspectRatio: effectiveWidth / _videoHeight,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'YouTube Shorts Example',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildHeightControls(
                    context,
                    title: 'Shorts Player Height',
                    value: _shortsHeight,
                    presets: const [420.0, 520.0, 640.0],
                    min: 320,
                    max: 760,
                    onChanged: (value) {
                      setState(() => _shortsHeight = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final effectiveWidth = width.isFinite ? width : 320.0;
                      return YoutubeEmbedPlayer(
                        key: ValueKey(
                          'shorts-${youtubeParams.controls}-${youtubeParams.autoplay}-${youtubeParams.loop}-${youtubeParams.rel}-${youtubeParams.theme}-${youtubeParams.color}-${settings.locale}-${settings.brightness}-${_shortsHeight.round()}',
                        ),
                        videoIdOrUrl: _shortsUrl,
                        maxWidth: effectiveWidth,
                        aspectRatio: effectiveWidth / _shortsHeight,
                        controls: youtubeParams.controls ?? true,
                        autoplay: youtubeParams.autoplay ?? false,
                        loop: youtubeParams.loop ?? false,
                        rel: youtubeParams.rel ?? false,
                        theme: youtubeParams.theme,
                        color: youtubeParams.color,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightControls(
    BuildContext context, {
    required String title,
    required double value,
    required List<double> presets,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.round()} px',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) ~/ 20).clamp(1, 100),
            label: '${value.round()} px',
            onChanged: onChanged,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in presets)
                ChoiceChip(
                  label: Text('${preset.round()} px'),
                  selected: value.round() == preset.round(),
                  onSelected: (_) => onChanged(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
