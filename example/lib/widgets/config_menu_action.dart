import 'package:embed_example/utils/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class ConfigMenuAction extends StatelessWidget {
  const ConfigMenuAction({super.key});

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
        return const _SettingsSheet();
      },
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late TextEditingController _proxyController;

  @override
  void initState() {
    super.initState();
    final settings =
        ExampleSettingsProvider.of(context, listen: false).settings;
    _proxyController = TextEditingController(text: settings.proxyUrl ?? '');
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
  }

  String? get _proxyError {
    final text = _proxyController.text.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !text.startsWith('http')) {
      return 'Enter a valid URL (e.g., http://localhost:8080/)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ExampleSettingsProvider.of(context);
    final settings = controller.settings;

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
                        selected: {settings.brightness},
                        onSelectionChanged: (val) {
                          controller.updateGeneral(brightness: val.first);
                          setState(() {});
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
                          ButtonSegment(value: 'zh', label: Text('ZH')),
                          ButtonSegment(value: 'ms', label: Text('MS')),
                        ],
                        selected: {settings.locale},
                        onSelectionChanged: (val) {
                          controller.updateGeneral(locale: val.first);
                          setState(() {});
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
                            value: settings.scrollable,
                            onChanged: (val) {
                              controller.updateGeneral(scrollable: val);
                              setState(() {});
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: const Text('Show "View" Footer'),
                            subtitle: const Text(
                              'Show link to original platform',
                            ),
                            value: settings.showFooter,
                            onChanged: (val) {
                              controller.updateGeneral(showFooter: val);
                              setState(() {});
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    _buildSection(
                      context,
                      title: 'API Proxy URL',
                      icon: Icons.dns_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Use a local or remote proxy to bypass CORS, protect API credentials, or centralize rate limiting.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'e.g., http://localhost:8080/',
                              errorText: _proxyError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              isDense: true,
                              suffixIcon:
                                  settings.proxyUrl != null &&
                                          settings.proxyUrl!.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _proxyController.clear();
                                          controller.updateGeneral(
                                            proxyUrl: null,
                                          );
                                          setState(() {});
                                        },
                                      )
                                      : null,
                            ),
                            controller: _proxyController,
                            onChanged: (val) {
                              controller.updateGeneral(
                                proxyUrl: val.isEmpty ? null : val,
                              );
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ActionChip(
                              avatar: const Icon(Icons.flash_on, size: 14),
                              label: const Text(
                                'Use Local (8080)',
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              onPressed: () {
                                const localUrl = 'http://localhost:8080/';
                                _proxyController.text = localUrl;
                                controller.updateGeneral(proxyUrl: localUrl);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context,
                      title: 'Cache Management',
                      icon: Icons.delete_sweep_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Clears all cached oEmbed responses. This will force the app to re-fetch data from the providers.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _confirmClearCache(context),
                            icon: const Icon(
                              Icons.cleaning_services_outlined,
                              size: 18,
                            ),
                            label: const Text('Clear OEmbed Cache'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Note: Only some providers (like X/Twitter, YouTube) support these settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cache?'),
            content: const Text(
              'This will remove all locally stored OEmbed responses. '
              'They will be re-fetched when needed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await EmbedScope.clearCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OEmbed cache cleared successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
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
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
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
