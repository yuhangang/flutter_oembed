import 'package:flutter/material.dart';
import 'package:oembed/oembed.dart';
import 'package:oembed_example/widgets/config_menu_action.dart';

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

  bool _controls = true;
  bool _autoplay = false;
  bool _loop = false;
  bool _musicInfo = true;
  bool _description = true;
  String _locale = 'en';
  Brightness _brightness = Brightness.light;
  bool _scrollable = false;
  bool _showFooter = false;

  @override
  Widget build(BuildContext context) {
    return OembedScope(
      config:
          OembedScope.configOf(context)?.copyWith(
            locale: _locale,
            brightness: _brightness,
          ) ??
          OembedConfig(locale: _locale, brightness: _brightness),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TikTok Native Player (v1)'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                            value: _controls,
                            onChanged: (val) => setState(() => _controls = val),
                            dense: true,
                          ),
                          SwitchListTile(
                            title: const Text('Autoplay'),
                            value: _autoplay,
                            onChanged: (val) => setState(() => _autoplay = val),
                            dense: true,
                          ),
                          SwitchListTile(
                            title: const Text('Loop'),
                            value: _loop,
                            onChanged: (val) => setState(() => _loop = val),
                            dense: true,
                          ),
                          SwitchListTile(
                            title: const Text('Music Info'),
                            value: _musicInfo,
                            onChanged: (val) => setState(() => _musicInfo = val),
                            dense: true,
                          ),
                          SwitchListTile(
                            title: const Text('Description'),
                            value: _description,
                            onChanged:
                                (val) => setState(() => _description = val),
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
                        '$_controls-$_autoplay-$_loop-$_musicInfo-$_description-$_locale-$_brightness',
                      ),
                      videoIdOrUrl: _testUrl,
                      controls: _controls,
                      autoplay: _autoplay,
                      loop: _loop,
                      musicInfo: _musicInfo,
                      description: _description,
                      // Typically TikTok fills a 9:16 aspect ratio bounds natively
                      aspectRatio: 9 / 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
