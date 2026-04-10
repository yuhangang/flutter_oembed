import 'package:embed_example/utils/platform_utils.dart';
import 'package:embed_example/utils/settings_controller.dart';
import 'package:embed_example/widgets/config_menu_action.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class OEmbedBlockEmbed extends CustomBlockEmbed {
  const OEmbedBlockEmbed(String url) : super('oembed', url);

  static OEmbedBlockEmbed fromKeyValue(String key, String value) =>
      OEmbedBlockEmbed(value);
}

class OEmbedEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'oembed';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data as String;
    final settings = ExampleSettingsProvider.of(context).settings;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: EmbedCard.url(
        url,
        embedConstraints: settings.embedConstraints,
        scrollable: settings.scrollable,
        lazyLoad: true,
        style: EmbedStyle(
          loadingBuilder:
              (context) => SocialEmbedPlaceholder(
                embedType: getEmbedTypeFromUrl(url) ?? EmbedType.other,
              ),
        ),
      ),
    );
  }
}

class QuillIntegrationPage extends StatefulWidget {
  const QuillIntegrationPage({super.key});

  @override
  State<QuillIntegrationPage> createState() => _QuillIntegrationPageState();
}

class _QuillIntegrationPageState extends State<QuillIntegrationPage> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final delta =
        Delta()
          ..insert('Flutter Quill Integration\n', {'header': 1})
          ..insert('This example shows how to use ')
          ..insert('flutter_oembed', {'bold': true})
          ..insert(' inside a rich text editor.\n\n')
          ..insert('Here is an embedded YouTube video:\n')
          ..insert(
            BlockEmbed.custom(
              const OEmbedBlockEmbed(
                'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              ),
            ).toJson(),
          )
          ..insert('\nAnd a TikTok video:\n')
          ..insert(
            BlockEmbed.custom(
              const OEmbedBlockEmbed(
                'https://www.tiktok.com/@scout2015/video/6718335390845095173',
              ),
            ).toJson(),
          )
          ..insert(
            '\nTry adding your own embed below using the plus button.\n',
          );

    _controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showOEmbedMenu() {
    final samples = [
      {
        'name': 'YouTube Video',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'icon': Icons.play_circle_fill,
        'color': Colors.red,
      },
      {
        'name': 'TikTok Trend',
        'url': 'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        'icon': Icons.music_note,
        'color': Colors.black,
      },
      {
        'name': 'X (Twitter) Post',
        'url': 'https://x.com/NASA/status/2037551448439787917',
        'icon': Icons.message,
        'color': Colors.blue,
      },
      {
        'name': 'GIPHY Embed',
        'url':
            'https://giphy.com/gifs/moodman-monkey-side-eye-sideeye-H5C8CevNMbpBqNqFjl',
        'icon': Icons.gif_box_rounded,
        'color': Colors.black,
      },
    ];

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Insert OEmbed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...samples.map(
                  (s) => ListTile(
                    leading: Icon(
                      s['icon'] as IconData,
                      color: s['color'] as Color,
                    ),
                    title: Text(s['name'] as String),
                    subtitle: Text(
                      s['url'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _insertEmbed(s['url'] as String);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_link),
                  title: const Text('Custom URL...'),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomUrlDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showCustomUrlDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Insert OEmbed'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Enter URL (YouTube, TikTok, etc.)',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final url = textController.text.trim();
                  if (url.isNotEmpty) {
                    _insertEmbed(url);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Insert'),
              ),
            ],
          ),
    );
  }

  void _insertEmbed(String url) {
    int index = _controller.selection.baseOffset;
    if (index < 0) {
      index = _controller.document.length;
    }
    _controller.document.insert(
      index,
      BlockEmbed.custom(OEmbedBlockEmbed(url)),
    );
    // Ensure a newline after the embed for better editing experience
    _controller.document.insert(index + 1, '\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quill Integration'),
        actions: const [ConfigMenuAction()],
      ),
      body: Column(
        children: [
          QuillSimpleToolbar(
            controller: _controller,
            config: QuillSimpleToolbarConfig(
              // Show basic buttons
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showListNumbers: true,
              showListBullets: true,
              showLink: true,
              showHeaderStyle: true,

              // Keep others hidden for a cleaner look
              showFontFamily: false,
              showFontSize: false,
              showStrikeThrough: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showListCheck: false,
              showCodeBlock: false,
              showQuote: false,
              showIndent: false,
              showSearchButton: false,
              showAlignmentButtons: false,
              showClearFormat: false,
              showSubscript: false,
              showSuperscript: false,
              showInlineCode: false,
              showSmallButton: false,
              showDirection: false,
              showDividers: false,

              // Add custom OEmbed button
              customButtons: [
                QuillToolbarCustomButtonOptions(
                  icon: const Icon(Icons.add_link, color: Colors.teal),
                  tooltip: 'Insert OEmbed',
                  onPressed: _showOEmbedMenu,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                config: QuillEditorConfig(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  embedBuilders: [OEmbedEmbedBuilder()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
