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
                  TikTokEmbedPlayer(
                    // You must change the key so the WebView reloads the URL
                    // when options like `controls` change
                    key: ValueKey(
                      '${tiktokParams.controls}-${tiktokParams.autoplay}-${tiktokParams.loop}-${tiktokParams.musicInfo}-${tiktokParams.description}-${settings.locale}-${settings.brightness}',
                    ),
                    videoIdOrUrl: _testUrl,
                    controls: tiktokParams.controls,
                    autoplay: tiktokParams.autoplay,
                    loop: tiktokParams.loop,
                    musicInfo: tiktokParams.musicInfo,
                    description: tiktokParams.description,
                    // Typically TikTok fills a 9:16 aspect ratio bounds natively
                    aspectRatio: 9 / 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
