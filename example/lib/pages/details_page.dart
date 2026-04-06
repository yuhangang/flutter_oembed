import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';
import 'package:embed_example/utils/settings_controller.dart';
import 'package:embed_example/utils/url_launcher_utils.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/settings_sheet.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';

class EmbedDetailsPage extends StatefulWidget {
  final Map<String, dynamic> sample;
  final int index;

  const EmbedDetailsPage({
    super.key,
    required this.sample,
    required this.index,
  });

  @override
  State<EmbedDetailsPage> createState() => _EmbedDetailsPageState();
}

class _EmbedDetailsPageState extends State<EmbedDetailsPage> {
  @override
  void initState() {
    super.initState();
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => VideoSettingsSheet(embedType: widget.sample['type']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsProvider.of(context).settings;
    final embedParams = _getParamsForType(widget.sample['type'], settings);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sample['source']} Embed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          const ConfigMenuAction(),
          if (widget.sample['type'] == EmbedType.vimeo ||
              widget.sample['type'] == EmbedType.x ||
              widget.sample['type'] == EmbedType.facebook ||
              widget.sample['type'] == EmbedType.facebook_post ||
              widget.sample['type'] == EmbedType.facebook_video ||
              widget.sample['type'] == EmbedType.instagram ||
              widget.sample['type'] == EmbedType.threads ||
              widget.sample['type'] == EmbedType.soundcloud ||
              widget.sample['type'] == EmbedType.tiktok_v1)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showSettingsSheet,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sample['source'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => openUrl(widget.sample['url']),
              child: Text(
                widget.sample['url'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decorationColor: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            EmbedCard.url(
              widget.sample['url'],
              embedType: widget.sample['type'],
              key: ValueKey(
                '${widget.sample['url']}-${settings.locale}-${settings.brightness}-$embedParams',
              ),
              scrollable: settings.scrollable,
              embedParams: embedParams,
              style: EmbedStyle(
                loadingBuilder:
                    (context) => SocialEmbedPlaceholder(
                      embedType: widget.sample['type'] ?? EmbedType.other,
                    ),
                footerBuilder:
                    settings.showFooter
                        ? (context, url) => Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => openUrl(url),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View on ${widget.sample['source'].split(' ').first}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BaseEmbedParams? _getParamsForType(
    EmbedType? type,
    ExampleSettings settings,
  ) {
    if (type == EmbedType.vimeo) return settings.vimeoParams;
    if (type == EmbedType.x) return settings.xParams;
    if (type?.isFacebook == true ||
        type == EmbedType.instagram ||
        type == EmbedType.threads) {
      return settings.metaParams;
    }
    if (type == EmbedType.soundcloud) return settings.soundCloudParams;
    if (type == EmbedType.tiktok_v1) return settings.tiktokParams;
    return null;
  }
}
