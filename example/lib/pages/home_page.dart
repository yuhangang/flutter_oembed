import 'package:embed_example/integrations/custom_provider_integration.dart';

import 'package:embed_example/integrations/html_integration.dart';
import 'package:embed_example/integrations/markdown_integration.dart';
import 'package:embed_example/integrations/quill_integration.dart';
import 'package:embed_example/integrations/webview_controls_integration.dart';
import 'package:embed_example/integrations/youtube_player_integration.dart';
import 'package:embed_example/models/sample_data.dart';
import 'package:embed_example/pages/details_page.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:embed_example/utils/settings_controller.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'flutter_embed',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          ListenableBuilder(
            listenable: ExampleSettingsProvider.of(context),
            builder: (context, _) {
              final proxyUrl =
                  ExampleSettingsProvider.of(context).settings.proxyUrl;
              if (proxyUrl == null || proxyUrl.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'CORS Proxy Active: $proxyUrl',
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    side: BorderSide.none,
                    label: Text(
                      'Proxy',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    avatar: Icon(
                      Icons.shield_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              );
            },
          ),
          const ConfigMenuAction(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Integrations & Players',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildIntegrationCard(
                  context,
                  title: 'Markdown',
                  subtitle: 'Embeds in markdown text',
                  icon: Icons.description_rounded,
                  color: Colors.blue,
                  page: const MarkdownIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'HTML',
                  subtitle: 'Embeds in parsed HTML',
                  icon: Icons.code_rounded,
                  color: Colors.orange,
                  page: const HtmlIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'YouTube',
                  subtitle: 'Native iframe player',
                  icon: Icons.smart_display_rounded,
                  color: Colors.red,
                  page: const YoutubePlayerIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'Quill Editor',
                  subtitle: 'Embeds in rich text',
                  icon: Icons.edit_note_rounded,
                  color: Colors.teal,
                  page: const QuillIntegrationPage(),
                ),

                _buildIntegrationCard(
                  context,
                  title: 'Custom Provider',
                  subtitle: 'Manual rules for Pinterest and more',
                  icon: Icons.extension_rounded,
                  color: Colors.brown,
                  page: const CustomProviderIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'Webview builder',
                  subtitle: 'Custom overlays using controls',
                  icon: Icons.control_camera_rounded,
                  color: Colors.indigo,
                  page: const WebViewControlsIntegrationPage(),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
              child: Text(
                'OEmbed Provider Samples (Verified)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final verifiedSamples =
                      samples
                          .where((s) => s['category'] == 'verified')
                          .toList();
                  final sample = verifiedSamples[index];
                  return _buildSampleCard(context, sample, index);
                },
                childCount:
                    samples.where((s) => s['category'] == 'verified').length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCard(
    BuildContext context,
    Map<String, dynamic> sample,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: _buildProviderLogo(sample['type']),
        ),
        title: Text(
          sample['source'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          sample['url'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EmbedDetailsPage(sample: sample, index: index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderLogo(EmbedType type) {
    final assetPath = getPlatformAsset(type);
    if (assetPath == null) {
      return const Icon(Icons.auto_awesome, size: 20, color: Colors.grey);
    }

    if (assetPath.endsWith('.png')) {
      return Image.asset(assetPath, fit: BoxFit.contain);
    }

    return SvgPicture.asset(
      assetPath,
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildIntegrationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      onTap:
          () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
