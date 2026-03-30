import 'package:flutter/material.dart';

class ConfigMenuAction extends StatelessWidget {
  final String currentLocale;
  final Brightness currentBrightness;
  final bool currentScrollable;
  final bool currentShowFooter;
  final Function(
    String locale,
    Brightness brightness,
    bool scrollable,
    bool showFooter,
  ) onChanged;

  const ConfigMenuAction({
    super.key,
    required this.currentLocale,
    required this.currentBrightness,
    required this.currentScrollable,
    required this.currentShowFooter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'OEmbed Settings',
      onPressed: () => _showSettings(context),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return _SettingsSheet(
          initialLocale: currentLocale,
          initialBrightness: currentBrightness,
          initialScrollable: currentScrollable,
          initialShowFooter: currentShowFooter,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  final String initialLocale;
  final Brightness initialBrightness;
  final bool initialScrollable;
  final bool initialShowFooter;
  final Function(
    String locale,
    Brightness brightness,
    bool scrollable,
    bool showFooter,
  ) onChanged;

  const _SettingsSheet({
    required this.initialLocale,
    required this.initialBrightness,
    required this.initialScrollable,
    required this.initialShowFooter,
    required this.onChanged,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late String _locale;
  late Brightness _brightness;
  late bool _scrollable;
  late bool _showFooter;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _brightness = widget.initialBrightness;
    _scrollable = widget.initialScrollable;
    _showFooter = widget.initialShowFooter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Embed Configuration',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const SizedBox(height: 12),
                    _buildSection(
                      context,
                      title: 'Preferred Theme',
                      icon: Icons.palette_outlined,
                      child: SegmentedButton<Brightness>(
                        segments: const [
                          ButtonSegment(
                            value: Brightness.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: Brightness.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {_brightness},
                        onSelectionChanged: (val) {
                          setState(() => _brightness = val.first);
                          widget.onChanged(
                            _locale,
                            _brightness,
                            _scrollable,
                            _showFooter,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Locale (Provider Language)',
                      icon: Icons.language_outlined,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('EN')),
                          ButtonSegment(value: 'es', label: Text('ES')),
                          ButtonSegment(value: 'zh', label: Text('ZH')),
                          ButtonSegment(value: 'ms', label: Text('MS')),
                        ],
                        selected: {_locale},
                        onSelectionChanged: (val) {
                          setState(() => _locale = val.first);
                          widget.onChanged(
                            _locale,
                            _brightness,
                            _scrollable,
                            _showFooter,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Global Behaviors',
                      icon: Icons.settings_suggest_outlined,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('WebView Scrollable'),
                            subtitle: const Text(
                              'Allow internal scrolling in WebView',
                            ),
                            value: _scrollable,
                            onChanged: (val) {
                              setState(() => _scrollable = val);
                              widget.onChanged(
                                _locale,
                                _brightness,
                                _scrollable,
                                _showFooter,
                              );
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: const Text('Show "View" Footer'),
                            subtitle: const Text('Show link to original platform'),
                            value: _showFooter,
                            onChanged: (val) {
                              setState(() => _showFooter = val);
                              widget.onChanged(
                                _locale,
                                _brightness,
                                _scrollable,
                                _showFooter,
                              );
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Note: Only some providers (like X/Twitter, YouTube) support these settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
