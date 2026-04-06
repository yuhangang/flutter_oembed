import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';
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
  String _locale = 'en';
  Brightness _brightness = Brightness.light;
  late bool _scrollable;
  late bool _showFooter;

  BaseEmbedParams? _embedParams;

  @override
  void initState() {
    super.initState();
    _scrollable = widget.sample['scrollable'] ?? false;
    _showFooter = widget.sample['showFooter'] ?? false;
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => VideoSettingsSheet(
            embedType: widget.sample['type'],
            vimeoParams: _embedParams as VimeoEmbedParams?,
            xParams: _embedParams as XEmbedParams?,
            metaParams: _embedParams as MetaEmbedParams?,
            soundCloudParams: _embedParams as SoundCloudEmbedParams?,
            tiktokParams: _embedParams as TikTokEmbedParams?,
            onChanged: (vimeo, x, meta, sc, tk) {
              setState(() {
                _embedParams = vimeo ?? x ?? meta ?? sc ?? tk;
              });
            },
          ),
    );
  }

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
          title: Text('${widget.sample['source']} Embed'),
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
                  style: const TextStyle(
                    color: Colors.blue,
                    decorationColor: Colors.blue,
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
                  '${widget.sample['url']}-$_locale-$_brightness-$_embedParams',
                ),
                tracking: EmbedTracking(
                  pageIdentifier: 'example_page',
                  source: widget.sample['source'],
                  contentId: 'content_${widget.index}',
                  elementId: 'element_${widget.index}',
                ),
                scrollable: _scrollable,
                embedParams: _embedParams,
                style: EmbedStyle(
                  loadingBuilder:
                      (context) => SocialEmbedPlaceholder(
                        embedType: widget.sample['type'] ?? EmbedType.other,
                      ),
                  footerBuilder:
                      _showFooter
                          ? (context, url) => Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              border: Border.all(color: Colors.grey.shade300),
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
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 16,
                                      color: Colors.blue.shade700,
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
      ),
    );
  }
}
