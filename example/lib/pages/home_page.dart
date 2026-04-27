import 'package:embed_example/integrations/custom_provider_integration.dart';

import 'package:embed_example/integrations/html_integration.dart';
import 'package:embed_example/integrations/markdown_integration.dart';
import 'package:embed_example/integrations/quill_integration.dart';
import 'package:embed_example/integrations/expandable_embed_integration.dart';
import 'package:embed_example/integrations/webview_controls_integration.dart';
import 'package:embed_example/integrations/youtube_player_integration.dart';
import 'package:embed_example/models/sample_data.dart';
import 'package:embed_example/pages/details_page.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'flutter_embed',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          actions: const [ConfigMenuAction()],
          bottom: TabBar(
            tabs: const [Tab(text: 'Integrations'), Tab(text: 'Providers')],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _buildIntegrationsTab(context),
            _buildProvidersTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationsTab(BuildContext context) {
    final integrations = [
      (
        title: 'Markdown',
        subtitle: 'Rich media rendering',
        icon: Icons.description_rounded,
        color: Colors.blue,
        page: const MarkdownIntegrationPage(),
      ),
      (
        title: 'HTML',
        subtitle: 'Rich media for HTML content',
        icon: Icons.code_rounded,
        color: Colors.orange,
        page: const HtmlIntegrationPage(),
      ),
      (
        title: 'YouTube',
        subtitle: 'Native iframe player',
        icon: Icons.smart_display_rounded,
        color: Colors.red,
        page: const YoutubePlayerIntegrationPage(),
      ),
      (
        title: 'Quill Editor',
        subtitle: 'Interactive rich text editing',
        icon: Icons.edit_note_rounded,
        color: Colors.teal,
        page: const QuillIntegrationPage(),
      ),
      (
        title: 'Custom Provider',
        subtitle: 'Manual rules for Pinterest and more',
        icon: Icons.extension_rounded,
        color: Colors.brown,
        page: const CustomProviderIntegrationPage(),
      ),
      (
        title: 'Webview builder',
        subtitle: 'Custom overlays using controls',
        icon: Icons.control_camera_rounded,
        color: Colors.indigo,
        page: const WebViewControlsIntegrationPage(),
      ),
      (
        title: 'Expandable Webview',
        subtitle: 'Webview with expand/collapse',
        icon: Icons.expand_rounded,
        color: Colors.teal,
        page: const ExpandableEmbedIntegrationPage(),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: integrations.length,
      itemBuilder: (context, index) {
        final item = integrations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildIntegrationCard(
            context,
            title: item.title,
            subtitle: item.subtitle,
            icon: item.icon,
            color: item.color,
            page: item.page,
          ),
        );
      },
    );
  }

  Widget _buildProvidersTab(BuildContext context) {
    final verifiedSamples =
        samples.where((s) => s['category'] == 'verified').toList();

    return GridView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: verifiedSamples.length,
      itemBuilder: (context, index) {
        final sample = verifiedSamples[index];
        return _buildSampleCard(context, sample, index);
      },
    );
  }

  Widget _buildSampleCard(
    BuildContext context,
    Map<String, dynamic> sample,
    int index,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => EmbedDetailsPage(sample: sample, index: index),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: _buildProviderLogo(sample['type']),
            ),
            const Spacer(),
            Text(
              sample['source'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              sample['url'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        subtitle: Text(
          subtitle,
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
      ),
    );
  }
}
