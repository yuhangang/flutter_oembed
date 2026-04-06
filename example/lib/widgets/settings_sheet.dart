import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';

class VideoSettingsSheet extends StatefulWidget {
  final EmbedType embedType;
  final VimeoEmbedParams? vimeoParams;
  final XEmbedParams? xParams;
  final MetaEmbedParams? metaParams;
  final SoundCloudEmbedParams? soundCloudParams;
  final TikTokEmbedParams? tiktokParams;
  final Function(
    VimeoEmbedParams?,
    XEmbedParams?,
    MetaEmbedParams?,
    SoundCloudEmbedParams?,
    TikTokEmbedParams?,
  )
  onChanged;

  const VideoSettingsSheet({
    super.key,
    required this.embedType,
    this.vimeoParams,
    this.xParams,
    this.metaParams,
    this.soundCloudParams,
    this.tiktokParams,
    required this.onChanged,
  });

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
  late String _xTheme;
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

  @override
  void initState() {
    super.initState();
    _vimeoAutoplay = widget.vimeoParams?.autoplay ?? false;
    _vimeoLoop = widget.vimeoParams?.loop ?? false;
    _vimeoMuted = widget.vimeoParams?.muted ?? false;
    _vimeoControls = widget.vimeoParams?.controls ?? true;
    _vimeoColor = widget.vimeoParams?.color ?? '00adef';

    _xDnt = widget.xParams?.dnt ?? true;
    _xTheme = widget.xParams?.theme ?? 'light';
    _xChrome =
        widget.xParams?.chrome ??
        ['noscrollbar', 'nofooter', 'noborders', 'transparent'];

    // Meta state
    _metaAdaptWidth = widget.metaParams?.adaptContainerWidth ?? true;
    _metaHideCover = widget.metaParams?.hideCover ?? false;
    _metaHideCaption = widget.metaParams?.hidecaption ?? false;
    _metaOmitScript = widget.metaParams?.omitscript ?? false;
    _metaShowFacepile = widget.metaParams?.showFacepile ?? true;
    _metaShowPosts = widget.metaParams?.showPosts ?? true;
    _metaSmallHeader = widget.metaParams?.smallHeader ?? false;
    _metaUseIframe = widget.metaParams?.useiframe ?? false;

    // SoundCloud state
    _scAutoPlay = widget.soundCloudParams?.autoPlay ?? false;
    _scShowComments = widget.soundCloudParams?.showComments ?? true;
    _scColor = widget.soundCloudParams?.color ?? 'ff5500';

    // TikTok state
    _tkControls = widget.tiktokParams?.controls ?? true;
    _tkAutoplay = widget.tiktokParams?.autoplay ?? false;
    _tkLoop = widget.tiktokParams?.loop ?? false;
    _tkMusicInfo = widget.tiktokParams?.musicInfo ?? true;
    _tkDescription = widget.tiktokParams?.description ?? true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _apply() {
    VimeoEmbedParams? vimeo;
    XEmbedParams? x;
    MetaEmbedParams? meta;
    SoundCloudEmbedParams? sc;
    TikTokEmbedParams? tk;

    if (widget.embedType == EmbedType.vimeo) {
      vimeo = VimeoEmbedParams(
        autoplay: _vimeoAutoplay,
        loop: _vimeoLoop,
        muted: _vimeoMuted,
        controls: _vimeoControls,
        color: _vimeoColor,
      );
    } else if (widget.embedType == EmbedType.x) {
      x = XEmbedParams(dnt: _xDnt, theme: _xTheme, chrome: _xChrome);
    } else if (widget.embedType.isFacebook ||
        widget.embedType == EmbedType.instagram ||
        widget.embedType == EmbedType.threads) {
      meta = MetaEmbedParams(
        adaptContainerWidth: _metaAdaptWidth,
        hideCover: _metaHideCover,
        hidecaption: _metaHideCaption,
        omitscript: _metaOmitScript,
        showFacepile: _metaShowFacepile,
        showPosts: _metaShowPosts,
        smallHeader: _metaSmallHeader,
        useiframe: _metaUseIframe,
      );
    } else if (widget.embedType == EmbedType.soundcloud) {
      sc = SoundCloudEmbedParams(
        autoPlay: _scAutoPlay,
        showComments: _scShowComments,
        color: _scColor,
      );
    } else if (widget.embedType == EmbedType.tiktok_v1) {
      tk = TikTokEmbedParams(
        controls: _tkControls,
        autoplay: _tkAutoplay,
        loop: _tkLoop,
        musicInfo: _tkMusicInfo,
        description: _tkDescription,
      );
    }

    widget.onChanged(vimeo, x, meta, sc, tk);
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Changes'),
                    ),
                    const SizedBox(height: 16),
                  ],
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
          color: Colors.grey[300],
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
        trailing: DropdownButton<String>(
          value: _xTheme,
          items: const [
            DropdownMenuItem(value: 'light', child: Text('Light')),
            DropdownMenuItem(value: 'dark', child: Text('Dark')),
          ],
          onChanged: (v) => setState(() => _xTheme = v!),
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
}
