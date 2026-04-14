import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class WebViewControlsIntegrationPage extends StatelessWidget {
  const WebViewControlsIntegrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView Controls')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This example demonstrates using the webViewBuilder to add a custom '
              'toolbar on top of the WebView using the exposed controls.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            EmbedCard(
              url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              webViewBuilder: (context, controls, child) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            ' Custom Controls',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: () => controls.reload(),
                            tooltip: 'Refresh',
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 18),
                            onPressed: () => controls.unmuteMedia(),
                            tooltip: 'Unmute',
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_mute, size: 18),
                            onPressed: () => controls.muteMedia(),
                            tooltip: 'Mute',
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause, size: 18),
                            onPressed: () => controls.pauseMedia(),
                            tooltip: 'Pause',
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow, size: 18),
                            onPressed: () => controls.resumeMedia(),
                            tooltip: 'Resume',
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      child: child,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Using WebViewController directly:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can also access the underlying WebViewController for more advanced '
              'tasks like checking the current URL or running custom JavaScript.',
            ),
            const SizedBox(height: 16),
            EmbedCard(
              url: 'https://x.com/NASA/status/2037551448439787917',
              webViewBuilder: (context, controls, child) {
                return Stack(
                  children: [
                    child,
                    Positioned(
                      top: 16,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final url = await controls.controller.currentUrl();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Current URL: $url')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
