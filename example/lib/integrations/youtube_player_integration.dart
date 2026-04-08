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
                  YoutubeEmbedPlayer(
                    // You must change the key so the WebView reloads the URL
                    // when options change
                    key: ValueKey(
                      '${youtubeParams.controls}-${youtubeParams.autoplay}-${youtubeParams.loop}-${youtubeParams.rel}-${youtubeParams.theme}-${youtubeParams.color}-${settings.locale}-${settings.brightness}',
                    ),
                    videoIdOrUrl: _testUrl,
                    controls: youtubeParams.controls ?? true,
                    autoplay: youtubeParams.autoplay ?? false,
                    loop: youtubeParams.loop ?? false,
                    rel: youtubeParams.rel ?? false,
                    theme: youtubeParams.theme,
                    color: youtubeParams.color,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'YouTube Shorts Example',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  YoutubeEmbedPlayer(
                    key: ValueKey(
                      'shorts-${youtubeParams.controls}-${youtubeParams.autoplay}-${youtubeParams.loop}-${youtubeParams.rel}-${youtubeParams.theme}-${youtubeParams.color}-${settings.locale}-${settings.brightness}',
                    ),
                    videoIdOrUrl: _shortsUrl,
                    aspectRatio: 9 / 16, // Shorts are vertical
                    controls: youtubeParams.controls ?? true,
                    autoplay: youtubeParams.autoplay ?? false,
                    loop: youtubeParams.loop ?? false,
                    rel: youtubeParams.rel ?? false,
                    theme: youtubeParams.theme,
                    color: youtubeParams.color,
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
}
