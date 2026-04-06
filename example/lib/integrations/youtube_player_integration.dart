import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';
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

  bool _controls = true;
  bool _autoplay = false;
  bool _loop = false;
  bool _rel = false;
  String _locale = 'en';
  Brightness _brightness = Brightness.light;
  bool _scrollable = false;
  bool _showFooter = false;

  @override
  Widget build(BuildContext context) {
    return EmbedScope(
      config:
          EmbedScope.configOf(
            context,
          )?.copyWith(locale: _locale, brightness: _brightness) ??
          EmbedConfig(locale: _locale, brightness: _brightness),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('YouTube Native Player IFrame'),
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
                            title: const Text('Show Related Videos (rel)'),
                            value: _rel,
                            onChanged: (val) => setState(() => _rel = val),
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
                        '$_controls-$_autoplay-$_loop-$_rel-$_locale-$_brightness',
                      ),
                      videoIdOrUrl: _testUrl,
                      controls: _controls,
                      autoplay: _autoplay,
                      loop: _loop,
                      rel: _rel,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'YouTube Shorts Example',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    YoutubeEmbedPlayer(
                      key: ValueKey(
                        'shorts-$_controls-$_autoplay-$_loop-$_rel-$_locale-$_brightness',
                      ),
                      videoIdOrUrl: _shortsUrl,
                      aspectRatio: 9 / 16, // Shorts are vertical
                      controls: _controls,
                      autoplay: _autoplay,
                      loop: _loop,
                      rel: _rel,
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
