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

  late final EmbedController _videoController = EmbedController(
    param: SocialEmbedParam(url: _testUrl, embedType: EmbedType.youtube),
  );
  late final EmbedController _shortsController = EmbedController(
    param: SocialEmbedParam(url: _shortsUrl, embedType: EmbedType.youtube),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _shortsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ExampleSettingsProvider.of(context);
    final settings = controller.settings;
    final youtubeParams = settings.youtubeParams;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('YouTube Native Player'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: const [ConfigMenuAction()],
          bottom: const TabBar(
            tabs: [Tab(text: 'Video (16:9)'), Tab(text: 'Shorts (9:16)')],
          ),
        ),
        body: TabBarView(
          children: [
            // Standard Video Tab
            _KeepAliveWrapper(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildGlobalSettings(context, controller, youtubeParams),
                    const SizedBox(height: 24),
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
                    _buildMediaControl(context, _videoController),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final effectiveWidth = width.isFinite ? width : 640.0;
                        return YoutubeEmbedPlayer(
                          videoIdOrUrl: _testUrl,
                          controller: _videoController,
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
                    SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
                  ],
                ),
              ),
            ),

            // Shorts Tab
            _KeepAliveWrapper(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildGlobalSettings(context, controller, youtubeParams),
                    const SizedBox(height: 24),
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
                    _buildMediaControl(context, _shortsController),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final effectiveWidth = width.isFinite ? width : 320.0;
                        return YoutubeEmbedPlayer(
                          videoIdOrUrl: _shortsUrl,
                          controller: _shortsController,
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
                    SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YouTube Native Player IFrame',
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
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Note: This widget is intended for simple use cases only. If you need full control over the player state, custom overlays, or the YouTube IFrame Player API, we strongly recommend using community packages like youtube_player_iframe.',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalSettings(
    BuildContext context,
    ExampleSettingsController controller,
    YoutubeEmbedParams youtubeParams,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Player Native Controls'),
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
                (val) =>
                    controller.updateYoutube(youtubeParams.copyWith(loop: val)),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Show Related Videos (rel)'),
            value: youtubeParams.rel ?? false,
            onChanged:
                (val) =>
                    controller.updateYoutube(youtubeParams.copyWith(rel: val)),
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaControl(BuildContext context, EmbedController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Media Controls',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildControlButton(
                  context,
                  width: buttonWidth,
                  icon: Icons.play_arrow_rounded,
                  label: 'Resume',
                  onPressed: () => controller.resumeMedia(),
                ),
                _buildControlButton(
                  context,
                  width: buttonWidth,
                  icon: Icons.pause_rounded,
                  label: 'Pause',
                  onPressed: () => controller.pauseMedia(),
                ),
                _buildControlButton(
                  context,
                  width: buttonWidth,
                  icon: Icons.volume_off_rounded,
                  label: 'Mute',
                  onPressed: () => controller.muteMedia(),
                ),
                _buildControlButton(
                  context,
                  width: buttonWidth,
                  icon: Icons.volume_up_rounded,
                  label: 'Unmute',
                  onPressed: () => controller.unmuteMedia(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
