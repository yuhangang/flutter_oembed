import 'package:embed_example/utils/settings_controller.dart';
import 'package:embed_example/utils/url_launcher_utils.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';
import 'package:embed_example/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

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

enum _ConstraintPreset {
  auto,
  // Spotify specific
  spotifySquare,
  spotifyRectangle,
  spotifyCustom,
  // Video specific
  video16v9,
  video9v16,
  video4v3,
}

class _EmbedDetailsPageState extends State<EmbedDetailsPage> {
  _ConstraintPreset _constraintPreset = _ConstraintPreset.auto;
  double _customHeight = 232.0; // Default for custom slider

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => VideoSettingsSheet(embedType: widget.sample['type']),
    );
  }

  Future<void> _showConstraintsSheet() async {
    final result = await showModalBottomSheet<(_ConstraintPreset, double?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ConstraintPresetSheet(
            initialPreset: _constraintPreset,
            initialCustomHeight: _customHeight,
            embedType: widget.sample['type'],
          ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _constraintPreset = result.$1;
      if (result.$2 != null) {
        _customHeight = result.$2!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ExampleSettingsProvider.of(context).settings;
    final embedType = widget.sample['type'] as EmbedType?;
    final embedParams = _getParamsForType(embedType, settings);
    final embedConstraints = _resolvedConstraints(settings);
    final supportsParameterSheet =
        embedType == EmbedType.vimeo ||
        embedType == EmbedType.x ||
        embedType?.isFacebook == true ||
        embedType == EmbedType.instagram ||
        embedType == EmbedType.threads ||
        embedType == EmbedType.soundcloud ||
        embedType == EmbedType.tiktok_v1;

    final supportsConstraints =
        embedType == EmbedType.spotify ||
        embedType == EmbedType.youtube ||
        embedType == EmbedType.tiktok_v1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sample['source']} Embed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [const ConfigMenuAction()],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (supportsConstraints)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                    onPressed: _showConstraintsSheet,
                    icon: const Icon(Icons.fit_screen_outlined),
                    label: const Text('Constraints'),
                  ),
                ),
              if (supportsParameterSheet) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showSettingsSheet,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Parameters'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      extendBody: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 16.0,
          bottom:
              24.0 + MediaQuery.viewPaddingOf(context).bottom + kToolbarHeight,
          left: 16.0,
          right: 16.0,
        ),
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
            if (embedType?.isFacebook == true ||
                embedType == EmbedType.instagram ||
                embedType == EmbedType.threads)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notice: Instagram, Threads, and Facebook embeds require a Facebook App ID and Client Token configured in your EmbedConfig.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              _constraintsStatusLabel(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            EmbedCard.url(
              widget.sample['url'],
              embedType: embedType,
              key: ValueKey(
                '${widget.sample['url']}-${settings.locale}-${settings.brightness}-$embedParams-${_constraintPreset.name}',
              ),
              embedConstraints: embedConstraints,
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

  EmbedConstraints? _resolvedConstraints(ExampleSettings settings) {
    final width = MediaQuery.sizeOf(context).width - 32;

    switch (_constraintPreset) {
      case _ConstraintPreset.auto:
        return null;
      case _ConstraintPreset.spotifySquare:
        return const EmbedConstraints(preferredHeight: 352);
      case _ConstraintPreset.spotifyRectangle:
        return const EmbedConstraints(preferredHeight: 152);
      case _ConstraintPreset.spotifyCustom:
        return EmbedConstraints(preferredHeight: _customHeight);
      case _ConstraintPreset.video16v9:
        return EmbedConstraints(preferredHeight: width / (16 / 9));
      case _ConstraintPreset.video9v16:
        return EmbedConstraints(preferredHeight: width / (9 / 16));
      case _ConstraintPreset.video4v3:
        return EmbedConstraints(preferredHeight: width / (4 / 3));
    }
  }

  String _constraintsStatusLabel() {
    final settings = ExampleSettingsProvider.of(context).settings;
    final constraints = _resolvedConstraints(settings);
    return constraints == null
        ? 'Constraints: auto'
        : 'Constraints: ${_formatConstraints(constraints)}';
  }

  String _formatConstraints(EmbedConstraints constraints) {
    final parts = <String>[];
    if (constraints.preferredHeight != null) {
      parts.add('preferredHeight: ${constraints.preferredHeight!.round()}');
    }
    if (constraints.minHeight != null) {
      parts.add('minHeight: ${constraints.minHeight!.round()}');
    }
    if (constraints.maxHeight != null) {
      parts.add('maxHeight: ${constraints.maxHeight!.round()}');
    }
    return 'EmbedConstraints(${parts.join(', ')})';
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

class _ConstraintPresetSheet extends StatefulWidget {
  final _ConstraintPreset initialPreset;
  final double initialCustomHeight;
  final EmbedType? embedType;

  const _ConstraintPresetSheet({
    required this.initialPreset,
    required this.initialCustomHeight,
    this.embedType,
  });

  @override
  State<_ConstraintPresetSheet> createState() => _ConstraintPresetSheetState();
}

class _ConstraintPresetSheetState extends State<_ConstraintPresetSheet> {
  late _ConstraintPreset _selectedPreset;
  late double _customHeight;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _customHeight = widget.initialCustomHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpotify = widget.embedType == EmbedType.spotify;
    final isVideo =
        widget.embedType == EmbedType.youtube ||
        widget.embedType == EmbedType.tiktok_v1;

    final options = <_ConstraintPreset>[_ConstraintPreset.auto];
    if (isSpotify) {
      options.addAll([
        _ConstraintPreset.spotifySquare,
        _ConstraintPreset.spotifyRectangle,
        _ConstraintPreset.spotifyCustom,
      ]);
    } else if (isVideo) {
      options.addAll([
        _ConstraintPreset.video16v9,
        _ConstraintPreset.video9v16,
        _ConstraintPreset.video4v3,
      ]);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Constraint Presets',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Text(
                      'Pick one preset to demonstrate how EmbedConstraints changes the same embed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final preset in options) ...[
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                preset == _selectedPreset
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                              title: Text(_presetLabel(preset)),
                              subtitle: Text(_presetDescription(preset)),
                              onTap: () {
                                setState(() => _selectedPreset = preset);
                                if (preset != _ConstraintPreset.spotifyCustom) {
                                  Navigator.pop(context, (
                                    _selectedPreset,
                                    _customHeight,
                                  ));
                                }
                              },
                            ),
                            if (preset == _ConstraintPreset.spotifyCustom &&
                                _selectedPreset ==
                                    _ConstraintPreset.spotifyCustom)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Height: ${_customHeight.round()}px',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Slider(
                                      value: _customHeight,
                                      min: 80,
                                      max: 600,
                                      divisions: 52,
                                      onChanged: (val) {
                                        setState(() => _customHeight = val);
                                      },
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed:
                                            () => Navigator.pop(context, (
                                              _selectedPreset,
                                              _customHeight,
                                            )),
                                        child: const Text('Apply Height'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _presetLabel(_ConstraintPreset preset) {
    return switch (preset) {
      _ConstraintPreset.auto => 'Auto',
      _ConstraintPreset.spotifySquare => 'Square',
      _ConstraintPreset.spotifyRectangle => 'Rectangle',
      _ConstraintPreset.spotifyCustom => 'Custom Height',
      _ConstraintPreset.video16v9 => '16:9',
      _ConstraintPreset.video9v16 => '9:16',
      _ConstraintPreset.video4v3 => '4:3',
    };
  }

  String _presetDescription(_ConstraintPreset preset) {
    return switch (preset) {
      _ConstraintPreset.auto =>
        'No override. Let the embed size itself naturally.',
      _ConstraintPreset.spotifySquare => 'Large Square (352px)',
      _ConstraintPreset.spotifyRectangle => 'Compact Rectangle (152px)',
      _ConstraintPreset.spotifyCustom => 'Slide to choose a custom height',
      _ConstraintPreset.video16v9 => 'Standard Widescreen',
      _ConstraintPreset.video9v16 => 'Portrait (Mobile)',
      _ConstraintPreset.video4v3 => 'Standard / Old School',
    };
  }
}
