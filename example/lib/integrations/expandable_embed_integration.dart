import 'package:embed_example/widgets/expandable_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class ExpandableEmbedIntegrationPage extends StatelessWidget {
  const ExpandableEmbedIntegrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expandable Embed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This example demonstrates how to use the webViewBuilder to wrap the '
              'embed in an expandable container. This is useful for long '
              'content like X (Twitter) that you '
              'want to keep compact initially.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            const Text(
              'X (Twitter) Post - Limited to 150px',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            EmbedCard(
              url: 'https://x.com/NASA/status/2037551448439787917',
              webViewBuilder: (context, controls, child) {
                return ExpandableEmbed(collapsedHeight: 150, child: child);
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Why use webViewBuilder?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'By using the builder, you get access to the child (the WebView) '
              'after it has been measured and sized by the library. You can then '
              'wrap it in any widget that controls its layout, like the '
              'ExpandableEmbed shown here, without interfering with the '
              'internal height measurement logic.',
            ),
          ],
        ),
      ),
    );
  }
}
