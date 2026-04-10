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

enum _ConstraintPreset { shared, auto, compact, bounded }

class _EmbedDetailsPageState extends State<EmbedDetailsPage> {
  _ConstraintPreset _constraintPreset = _ConstraintPreset.shared;

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
    final result = await showModalBottomSheet<_ConstraintPreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ConstraintPresetSheet(initialPreset: _constraintPreset),
    );

    if (result == null || !mounted) return;
    setState(() => _constraintPreset = result);
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
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          bottom: 24.0 + MediaQuery.viewPaddingOf(context).bottom,
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
              _constraintsStatusLabel(settings),
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
    switch (_constraintPreset) {
      case _ConstraintPreset.shared:
        return settings.embedConstraints;
      case _ConstraintPreset.auto:
        return null;
      case _ConstraintPreset.compact:
        return const EmbedConstraints(preferredHeight: 96);
      case _ConstraintPreset.bounded:
        return const EmbedConstraints(
          preferredHeight: 260,
          minHeight: 200,
          maxHeight: 320,
        );
    }
  }

  String _constraintsStatusLabel(ExampleSettings settings) {
    final constraints = _resolvedConstraints(settings);
    if (_constraintPreset == _ConstraintPreset.shared) {
      return constraints == null
          ? 'Shared constraints: auto'
          : 'Shared constraints: ${_formatConstraints(constraints)}';
    }
    return constraints == null
        ? 'Preset constraints: auto'
        : 'Preset constraints: ${_formatConstraints(constraints)}';
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

class _ConstraintPresetSheet extends StatelessWidget {
  final _ConstraintPreset initialPreset;

  const _ConstraintPresetSheet({required this.initialPreset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.8,
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
                    for (final preset in _ConstraintPreset.values)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            preset == initialPreset
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text(_presetLabel(preset)),
                          subtitle: Text(_presetDescription(preset)),
                          onTap: () => Navigator.pop(context, preset),
                        ),
                      ),
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
      _ConstraintPreset.shared => 'Shared',
      _ConstraintPreset.auto => 'Auto',
      _ConstraintPreset.compact => 'Compact',
      _ConstraintPreset.bounded => 'Bounded',
    };
  }

  String _presetDescription(_ConstraintPreset preset) {
    return switch (preset) {
      _ConstraintPreset.shared =>
        'Use the global example setting from the main config sheet.',
      _ConstraintPreset.auto =>
        'No override. Let the embed size itself naturally.',
      _ConstraintPreset.compact => 'EmbedConstraints(preferredHeight: 180)',
      _ConstraintPreset.bounded =>
        'EmbedConstraints(preferredHeight: 260, minHeight: 200, maxHeight: 320)',
    };
  }
}
