import 'package:embed_example/utils/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:embed_example/widgets/config_menu_action.dart';

class TikTokPlayerIntegrationPage extends StatefulWidget {
  const TikTokPlayerIntegrationPage({super.key});

  @override
  State<TikTokPlayerIntegrationPage> createState() =>
      _TikTokPlayerIntegrationState();
}

class _TikTokPlayerIntegrationState extends State<TikTokPlayerIntegrationPage> {
  // A test video from the tiktok dev documentation
  final _testUrl =
      'https://www.tiktok.com/@scout2015/video/6718335390845095173';
  double _playerHeight = 520;

  @override
  Widget build(BuildContext context) {
    final controller = ExampleSettingsProvider.of(context);
    final settings = controller.settings;
    final tiktokParams = settings.tiktokParams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TikTok Native Player (v1)'),
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
                    'TikTok Embed Player',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This standalone player uses tiktok.com/player/v1/ instead of standard oEmbed. It allows configuring precise playback controls.',
                    style: TextStyle(color: Colors.grey),
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
                          value: tiktokParams.controls,
                          onChanged:
                              (val) => controller.updateTikTok(
                                tiktokParams.copyWith(controls: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Autoplay'),
                          value: tiktokParams.autoplay,
                          onChanged:
                              (val) => controller.updateTikTok(
                                tiktokParams.copyWith(autoplay: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Loop'),
                          value: tiktokParams.loop,
                          onChanged:
                              (val) => controller.updateTikTok(
                                tiktokParams.copyWith(loop: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Music Info'),
                          value: tiktokParams.musicInfo,
                          onChanged:
                              (val) => controller.updateTikTok(
                                tiktokParams.copyWith(musicInfo: val),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Description'),
                          value: tiktokParams.description,
                          onChanged:
                              (val) => controller.updateTikTok(
                                tiktokParams.copyWith(description: val),
                              ),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeightControls(
                    context,
                    title: 'Player Frame Height',
                    value: _playerHeight,
                    presets: const [420.0, 520.0, 640.0],
                    onChanged: (value) {
                      setState(() => _playerHeight = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final effectiveWidth = width.isFinite ? width : 320.0;
                      return TikTokEmbedPlayer(
                        // You must change the key so the WebView reloads the URL
                        // when options like `controls` change
                        key: ValueKey(
                          '${tiktokParams.controls}-${tiktokParams.autoplay}-${tiktokParams.loop}-${tiktokParams.musicInfo}-${tiktokParams.description}-${settings.locale}-${settings.brightness}-${_playerHeight.round()}',
                        ),
                        videoIdOrUrl: _testUrl,
                        controls: tiktokParams.controls,
                        autoplay: tiktokParams.autoplay,
                        loop: tiktokParams.loop,
                        musicInfo: tiktokParams.musicInfo,
                        description: tiktokParams.description,
                        maxWidth: effectiveWidth,
                        aspectRatio: effectiveWidth / _playerHeight,
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
            min: 320,
            max: 760,
            divisions: 22,
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
