import 'package:embed_example/utils/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class VideoSettingsSheet extends StatefulWidget {
  final EmbedType embedType;

  const VideoSettingsSheet({super.key, required this.embedType});

  @override
  State<VideoSettingsSheet> createState() => _VideoSettingsSheetState();
}

class _VideoSettingsSheetState extends State<VideoSettingsSheet> {
  // Vimeo state
  late bool _vimeoAutoplay;
  late bool _vimeoLoop;
  late bool _vimeoMuted;
  late bool _vimeoControls;
  late String _vimeoColor;

  // X state
  late bool _xDnt;
  late String? _xTheme;
  late List<String> _xChrome;

  // Meta state
  late bool _metaAdaptWidth;
  late bool _metaHideCover;
  late bool _metaHideCaption;
  late bool _metaOmitScript;
  late bool _metaShowFacepile;
  late bool _metaShowPosts;
  late bool _metaSmallHeader;
  late bool _metaUseIframe;

  // SoundCloud state
  late bool _scAutoPlay;
  late bool _scShowComments;
  late String _scColor;

  // TikTok state
  late bool _tkControls;
  late bool _tkAutoplay;
  late bool _tkLoop;
  late bool _tkMusicInfo;
  late bool _tkDescription;

  // YouTube state
  late String? _ytTheme;
  late String? _ytColor;

  @override
  void initState() {
    super.initState();
    final settings = ExampleSettingsProvider.of(context).settings;

    _vimeoAutoplay = settings.vimeoParams.autoplay ?? false;
    _vimeoLoop = settings.vimeoParams.loop ?? false;
    _vimeoMuted = settings.vimeoParams.muted ?? false;
    _vimeoControls = settings.vimeoParams.controls ?? true;
    _vimeoColor = settings.vimeoParams.color ?? '00adef';

    _xDnt = settings.xParams.dnt ?? true;
    _xTheme = settings.xParams.theme;
    _xChrome = List.from(
      settings.xParams.chrome ??
          ['noscrollbar', 'nofooter', 'noborders', 'transparent'],
    );

    // Meta state
    _metaAdaptWidth = settings.metaParams.adaptContainerWidth ?? true;
    _metaHideCover = settings.metaParams.hideCover ?? false;
    _metaHideCaption = settings.metaParams.hidecaption ?? false;
    _metaOmitScript = settings.metaParams.omitscript ?? false;
    _metaShowFacepile = settings.metaParams.showFacepile ?? true;
    _metaShowPosts = settings.metaParams.showPosts ?? true;
    _metaSmallHeader = settings.metaParams.smallHeader ?? false;
    _metaUseIframe = settings.metaParams.useiframe ?? false;

    // SoundCloud state
    _scAutoPlay = settings.soundCloudParams.autoPlay ?? false;
    _scShowComments = settings.soundCloudParams.showComments ?? true;
    _scColor = settings.soundCloudParams.color ?? 'ff5500';

    // TikTok state
    _tkControls = settings.tiktokParams.controls;
    _tkAutoplay = settings.tiktokParams.autoplay;
    _tkLoop = settings.tiktokParams.loop;
    _tkMusicInfo = settings.tiktokParams.musicInfo;
    _tkDescription = settings.tiktokParams.description;

    _ytTheme = settings.youtubeParams.theme;
    _ytColor = settings.youtubeParams.color;
  }

  void _apply() {
    final controller = ExampleSettingsProvider.of(context);

    if (widget.embedType == EmbedType.vimeo) {
      controller.updateVimeo(
        VimeoEmbedParams(
          autoplay: _vimeoAutoplay,
          loop: _vimeoLoop,
          muted: _vimeoMuted,
          controls: _vimeoControls,
          color: _vimeoColor,
        ),
      );
    } else if (widget.embedType == EmbedType.x) {
      controller.updateX(
        XEmbedParams(dnt: _xDnt, theme: _xTheme, chrome: _xChrome),
      );
    } else if (widget.embedType.isFacebook ||
        widget.embedType == EmbedType.instagram ||
        widget.embedType == EmbedType.threads) {
      controller.updateMeta(
        MetaEmbedParams(
          adaptContainerWidth: _metaAdaptWidth,
          hideCover: _metaHideCover,
          hidecaption: _metaHideCaption,
          omitscript: _metaOmitScript,
          showFacepile: _metaShowFacepile,
          showPosts: _metaShowPosts,
          smallHeader: _metaSmallHeader,
          useiframe: _metaUseIframe,
        ),
      );
    } else if (widget.embedType == EmbedType.soundcloud) {
      controller.updateSoundCloud(
        SoundCloudEmbedParams(
          autoPlay: _scAutoPlay,
          showComments: _scShowComments,
          color: _scColor,
        ),
      );
    } else if (widget.embedType == EmbedType.tiktok_v1) {
      controller.updateTikTok(
        TikTokEmbedParams(
          controls: _tkControls,
          autoplay: _tkAutoplay,
          loop: _tkLoop,
          musicInfo: _tkMusicInfo,
          description: _tkDescription,
        ),
      );
    } else if (widget.embedType == EmbedType.youtube) {
      controller.updateYoutube(
        YoutubeEmbedParams(theme: _ytTheme, color: _ytColor),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${widget.embedType.name.toUpperCase()} Parameters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.embedType == EmbedType.vimeo)
                      ..._buildVimeoSettings(),
                    if (widget.embedType == EmbedType.x) ..._buildXSettings(),
                    if (widget.embedType.isFacebook ||
                        widget.embedType == EmbedType.instagram ||
                        widget.embedType == EmbedType.threads)
                      ..._buildMetaSettings(),
                    if (widget.embedType == EmbedType.soundcloud)
                      ..._buildSoundCloudSettings(),
                    if (widget.embedType == EmbedType.tiktok_v1)
                      ..._buildTikTokSettings(),
                    if (widget.embedType == EmbedType.youtube)
                      ..._buildYoutubeSettings(),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Apply Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  List<Widget> _buildVimeoSettings() {
    return [
      SwitchListTile(
        title: const Text('Autoplay'),
        value: _vimeoAutoplay,
        onChanged: (v) => setState(() => _vimeoAutoplay = v),
      ),
      SwitchListTile(
        title: const Text('Loop'),
        value: _vimeoLoop,
        onChanged: (v) => setState(() => _vimeoLoop = v),
      ),
      SwitchListTile(
        title: const Text('Muted'),
        value: _vimeoMuted,
        onChanged: (v) => setState(() => _vimeoMuted = v),
      ),
      SwitchListTile(
        title: const Text('Show Controls'),
        value: _vimeoControls,
        onChanged: (v) => setState(() => _vimeoControls = v),
      ),
      ListTile(
        title: const Text('Brand Color (Hex)'),
        subtitle: Text('#$_vimeoColor'),
        trailing: SizedBox(
          width: 100,
          child: TextField(
            decoration: const InputDecoration(isDense: true),
            onChanged: (v) => _vimeoColor = v.replaceAll('#', ''),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildXSettings() {
    return [
      SwitchListTile(
        title: const Text('Do Not Track (DNT)'),
        value: _xDnt,
        onChanged: (v) => setState(() => _xDnt = v),
      ),
      ListTile(
        title: const Text('Theme'),
        subtitle: const Text('Derive from app or force a specific look'),
        trailing: DropdownButton<String?>(
          value: _xTheme,
          items: const [
            DropdownMenuItem(value: null, child: Text('Automatic')),
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
          ],
          onChanged: (v) => setState(() => _xTheme = v),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Chrome Elements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ...[
        'noheader',
        'nofooter',
        'noborders',
        'noscrollbar',
        'transparent',
      ].map(
        (e) => CheckboxListTile(
          title: Text(e),
          value: _xChrome.contains(e),
          onChanged: (v) {
            setState(() {
              if (v!) {
                _xChrome.add(e);
              } else {
                _xChrome.remove(e);
              }
            });
          },
        ),
      ),
    ];
  }

  List<Widget> _buildMetaSettings() {
    final isPage = widget.embedType == EmbedType.facebook;
    final isInstagramOrThreads =
        widget.embedType == EmbedType.instagram ||
        widget.embedType == EmbedType.threads;
    final isPostOrVideo =
        widget.embedType == EmbedType.facebook_post ||
        widget.embedType == EmbedType.facebook_video;

    return [
      SwitchListTile(
        title: const Text('Omit Script'),
        subtitle: const Text('Hide injected JS'),
        value: _metaOmitScript,
        onChanged: (v) => setState(() => _metaOmitScript = v),
      ),
      if (isInstagramOrThreads)
        SwitchListTile(
          title: const Text('Hide Caption'),
          value: _metaHideCaption,
          onChanged: (v) => setState(() => _metaHideCaption = v),
        ),
      if (isPage) ...[
        SwitchListTile(
          title: const Text('Adapt Width'),
          value: _metaAdaptWidth,
          onChanged: (v) => setState(() => _metaAdaptWidth = v),
        ),
        SwitchListTile(
          title: const Text('Hide Cover'),
          value: _metaHideCover,
          onChanged: (v) => setState(() => _metaHideCover = v),
        ),
        SwitchListTile(
          title: const Text('Small Header'),
          value: _metaSmallHeader,
          onChanged: (v) => setState(() => _metaSmallHeader = v),
        ),
        SwitchListTile(
          title: const Text('Show Facepile'),
          value: _metaShowFacepile,
          onChanged: (v) => setState(() => _metaShowFacepile = v),
        ),
        SwitchListTile(
          title: const Text('Show Posts'),
          value: _metaShowPosts,
          onChanged: (v) => setState(() => _metaShowPosts = v),
        ),
      ],
      if (isPostOrVideo)
        SwitchListTile(
          title: const Text('Use IFrame'),
          value: _metaUseIframe,
          onChanged: (v) => setState(() => _metaUseIframe = v),
        ),
    ];
  }

  List<Widget> _buildSoundCloudSettings() {
    return [
      SwitchListTile(
        title: const Text('Auto Play'),
        value: _scAutoPlay,
        onChanged: (v) => setState(() => _scAutoPlay = v),
      ),
      SwitchListTile(
        title: const Text('Show Comments'),
        value: _scShowComments,
        onChanged: (v) => setState(() => _scShowComments = v),
      ),
      ListTile(
        title: const Text('Brand Color (Hex)'),
        subtitle: Text('#$_scColor'),
        trailing: SizedBox(
          width: 100,
          child: TextField(
            decoration: const InputDecoration(isDense: true),
            onChanged: (v) => _scColor = v.replaceAll('#', ''),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTikTokSettings() {
    return [
      SwitchListTile(
        title: const Text('Show Controls'),
        value: _tkControls,
        onChanged: (v) => setState(() => _tkControls = v),
      ),
      SwitchListTile(
        title: const Text('Autoplay'),
        value: _tkAutoplay,
        onChanged: (v) => setState(() => _tkAutoplay = v),
      ),
      SwitchListTile(
        title: const Text('Loop'),
        value: _tkLoop,
        onChanged: (v) => setState(() => _tkLoop = v),
      ),
      SwitchListTile(
        title: const Text('Music Info'),
        value: _tkMusicInfo,
        onChanged: (v) => setState(() => _tkMusicInfo = v),
      ),
      SwitchListTile(
        title: const Text('Description'),
        value: _tkDescription,
        onChanged: (v) => setState(() => _tkDescription = v),
      ),
    ];
  }

  List<Widget> _buildYoutubeSettings() {
    return [
      ListTile(
        title: const Text('Theme'),
        subtitle: const Text('Automatic follows global app theme'),
        trailing: DropdownButton<String?>(
          value: _ytTheme,
          items: const [
            DropdownMenuItem(value: null, child: Text('Automatic')),
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
          ],
          onChanged: (v) => setState(() => _ytTheme = v),
        ),
      ),
      ListTile(
        title: const Text('ProgressBar Color'),
        trailing: DropdownButton<String?>(
          value: _ytColor,
          items: const [
            DropdownMenuItem(value: null, child: Text('Default (Red)')),
            DropdownMenuItem(value: 'red', child: Text('Red')),
            DropdownMenuItem(value: 'white', child: Text('White')),
          ],
          onChanged: (v) => setState(() => _ytColor = v),
        ),
      ),
    ];
  }
}
