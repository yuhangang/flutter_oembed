import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oembed/oembed.dart';
import 'package:oembed_example/integrations/markdown_integration.dart';

import 'package:oembed_example/integrations/html_integration.dart';
import 'package:oembed_example/integrations/tiktok_player_integration.dart';
import 'package:oembed_example/integrations/youtube_player_integration.dart';
import 'package:oembed_example/integrations/quill_integration.dart';
import 'package:oembed_example/widgets/config_menu_action.dart';
import 'package:oembed_example/utils/url_launcher_utils.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return OembedScope(
      config: OembedConfig(
        providers: OembedProviderConfig(
          // Only allow these providers (comment out to enable all)
          // enabledProviders: {'YouTube', 'Spotify', 'Vimeo', 'TikTok', 'SoundCloud'},
          providerRenderModes: {
            // Use iframe mode for YouTube & Spotify (skips OEmbed API)
            'YouTube': OembedRenderMode.iframe,
            'Spotify': OembedRenderMode.iframe,
          },
        ),
        cache: const OembedCacheConfig(
          enabled: true,
          defaultCacheDuration: Duration(hours: 12),
          respectApiCacheAge: true,
        ),
        // facebookAppId: 'YOUR_APP_ID',
        // facebookClientToken: 'YOUR_CLIENT_TOKEN',
        onLinkTap: (url, data) {
          debugPrint(
            'User clicked on link: $url (Provider: ${data?.providerName})',
          );
          if (url.contains('google.com')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blocking navigation to Google')),
            );
          } else {
            openUrl(url);
          }
        },
        style: OembedStyle(
          errorBuilder: (context, error) {
            return const SocialEmbedErrorPlaceholder(
              embedType: EmbedType.other,
            );
          },
        ),
      ),
      child: MaterialApp(
        title: 'OEmbed Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('zh'), Locale('es')],
        home: const MyHomePage(),
      ),
    );
  }
}

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

  static const List<Map<String, dynamic>> samples = [
    {
      'url': 'https://www.youtube.com/watch?v=YSJY3DvnybE',
      'type': EmbedType.youtube,
      'source': 'YouTube',
    },
    {
      'url': 'https://www.dailymotion.com/video/x8q7p6v',
      'type': EmbedType.dailymotion,
      'source': 'Dailymotion',
    },
    {
      'url': 'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      'type': EmbedType.tiktok,
      'source': 'TikTok',
    },
    {
      'url': 'https://twitter.com/X/status/1328842765115920384',
      'type': EmbedType.x,
      'source': 'X',
    },
    {
      'url': 'https://www.instagram.com/p/DWPlkDrD7Jv/',
      'type': EmbedType.instagram,
      'source': 'Instagram',
    },
    {
      'url': 'https://www.threads.net/@zuck/post/Cx_M_y-L_y-',
      'type': EmbedType.threads,
      'source': 'Threads',
    },
    {
      'url': 'https://open.spotify.com/track/4JOEMgLkrHp8K1XNmyNffH',
      'type': EmbedType.spotify,
      'source': 'Spotify',
    },
    {
      'url':
          'https://www.reddit.com/r/flutterdev/comments/17yv8y8/how_to_implement_oembed_in_flutter/',
      'type': EmbedType.reddit,
      'source': 'Reddit',
    },
    {
      'url': 'https://vimeo.com/22439234',
      'type': EmbedType.vimeo,
      'source': 'Vimeo',
    },
    {
      'url': 'https://x.com/NASA/status/2037551448439787917',
      'type': EmbedType.x,
      'source': 'X (with Video)',
    },
    {
      'url': 'https://www.youtube.com/watch?v=YSJY3DvnybE',
      'type': EmbedType.youtube,
      'source': 'YouTube (Interactive)',
    },
    {
      'url': 'https://www.youtube.com/watch?v=YSJY3DvnybE',
      'type': EmbedType.youtube,
      'source': 'YouTube (Standard)',
    },
    {
      'url': 'https://soundcloud.com/theglitchmob/fortune-days',
      'type': EmbedType.soundcloud,
      'source': 'SoundCloud',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'flutter_oembed',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Integrations & Players',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildIntegrationCard(
                  context,
                  title: 'Markdown',
                  subtitle: 'Embeds in markdown text',
                  icon: Icons.description_rounded,
                  color: Colors.blue,
                  page: const MarkdownIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'HTML',
                  subtitle: 'Embeds in parsed HTML',
                  icon: Icons.code_rounded,
                  color: Colors.orange,
                  page: const HtmlIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'TikTok v1',
                  subtitle: 'Native display player',
                  icon: Icons.play_arrow_rounded,
                  color: Colors.black,
                  page: const TikTokPlayerIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'YouTube',
                  subtitle: 'Native iframe player',
                  icon: Icons.smart_display_rounded,
                  color: Colors.red,
                  page: const YoutubePlayerIntegrationPage(),
                ),
                _buildIntegrationCard(
                  context,
                  title: 'Quill Editor',
                  subtitle: 'Embeds in rich text',
                  icon: Icons.edit_note_rounded,
                  color: Colors.teal,
                  page: const QuillIntegrationPage(),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
              child: Text(
                'OEmbed Provider Samples',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final sample = samples[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      sample['source'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      sample['url'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EmbedDetailsPage(
                                sample: sample,
                                index: index,
                              ),
                        ),
                      );
                    },
                  ),
                );
              }, childCount: samples.length),
            ),
          ),
        ],
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
    return InkWell(
      onTap:
          () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _scrollable = widget.sample['scrollable'] ?? false;
    _showFooter = widget.sample['showFooter'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return OembedScope(
      config:
          OembedScope.configOf(
            context,
          )?.copyWith(locale: _locale, brightness: _brightness) ??
          OembedConfig(locale: _locale, brightness: _brightness),
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
              SelectableText(
                widget.sample['url'],
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              EmbedCard(
                key: ValueKey('${widget.sample['url']}-$_locale-$_brightness'),
                url: widget.sample['url'],
                embedType: widget.sample['type'],
                pageIdentifier: 'example_page',
                source: widget.sample['source'],
                contentId: 'content_${widget.index}',
                elementId: 'element_${widget.index}',
                extraIdentifier: 'extra_${widget.index}',
                scrollable: _scrollable,
                style: OembedStyle(
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

// Platform logo asset mapping
String? _getPlatformAsset(EmbedType type) {
  switch (type) {
    case EmbedType.youtube:
      return 'assets/logos/youtube.svg';
    case EmbedType.facebook:
    case EmbedType.facebook_post:
    case EmbedType.facebook_video:
      return 'assets/logos/facebook.svg';
    case EmbedType.instagram:
      return 'assets/logos/instagram.svg';
    case EmbedType.tiktok:
      return 'assets/logos/tiktok.svg';
    case EmbedType.x:
      return 'assets/logos/x.svg';
    case EmbedType.spotify:
      return 'assets/logos/spotify.svg';
    case EmbedType.vimeo:
      return 'assets/logos/vimeo.svg';
    case EmbedType.dailymotion:
      return 'assets/logos/dailymotion.svg';
    case EmbedType.soundcloud:
      return 'assets/logos/soundcloud.svg';
    case EmbedType.threads:
      return 'assets/logos/threads.svg';
    case EmbedType.reddit:
      return 'assets/logos/reddit.svg';
    default:
      return null;
  }
}

class SocialEmbedPlaceholder extends StatefulWidget {
  final EmbedType embedType;

  const SocialEmbedPlaceholder({super.key, required this.embedType});

  @override
  State<SocialEmbedPlaceholder> createState() => _SocialEmbedPlaceholderState();
}

class _SocialEmbedPlaceholderState extends State<SocialEmbedPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getPlatformTheme(widget.embedType);
    final assetPath = _getPlatformAsset(widget.embedType);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Progress Ring
                  RotationTransition(
                    turns: _controller,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  // Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor.withValues(alpha: 0.05),
                    ),
                    padding: const EdgeInsets.all(14),
                    child:
                        assetPath != null
                            ? SvgPicture.asset(
                              assetPath,
                              colorFilter: ColorFilter.mode(
                                theme.primaryColor,
                                BlendMode.srcIn,
                              ),
                            )
                            : Icon(
                              Icons.auto_awesome,
                              color: theme.primaryColor,
                              size: 24,
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PlatformTheme _getPlatformTheme(EmbedType type) {
    switch (type) {
      case EmbedType.youtube:
        return _PlatformTheme(
          primaryColor: const Color(0xFFFF0000),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFFC40000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.facebook:
      case EmbedType.facebook_post:
      case EmbedType.facebook_video:
        return _PlatformTheme(
          primaryColor: const Color(0xFF1877F2),
          gradient: const LinearGradient(
            colors: [Color(0xFF1877F2), Color(0xFF0056B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.instagram:
        return _PlatformTheme(
          primaryColor: const Color(0xFFE4405F),
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.tiktok:
        return _PlatformTheme(
          primaryColor: Colors.black,
          gradient: const LinearGradient(
            colors: [Color(0xFF010101), Color(0xFF25F4EE), Color(0xFFFE2C55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.x:
        return _PlatformTheme(
          primaryColor: Colors.black,
          gradient: const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.spotify:
        return _PlatformTheme(
          primaryColor: const Color(0xFF1DB954),
          gradient: const LinearGradient(
            colors: [Color(0xFF1DB954), Color(0xFF191414)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.vimeo:
        return _PlatformTheme(
          primaryColor: const Color(0xFF1AB7EA),
          gradient: const LinearGradient(
            colors: [Color(0xFF1AB7EA), Color(0xFF0096FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.dailymotion:
        return _PlatformTheme(
          primaryColor: const Color(0xFF0066DC),
          gradient: const LinearGradient(
            colors: [Color(0xFF0066DC), Color(0xFF004499)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.soundcloud:
        return _PlatformTheme(
          primaryColor: const Color(0xFFFF5500),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5500), Color(0xFFFF2200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.threads:
        return _PlatformTheme(
          primaryColor: Colors.black,
          gradient: const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case EmbedType.reddit:
        return _PlatformTheme(
          primaryColor: const Color(0xFFFF4500),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4500), Color(0xFFFF7700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        return _PlatformTheme(
          primaryColor: Colors.blueGrey,
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.blueGrey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }
}

class _PlatformTheme {
  final Color primaryColor;
  final Gradient gradient;

  _PlatformTheme({required this.primaryColor, required this.gradient});
}

class SocialEmbedErrorPlaceholder extends StatelessWidget {
  final EmbedType embedType;

  const SocialEmbedErrorPlaceholder({super.key, required this.embedType});

  @override
  Widget build(BuildContext context) {
    // We use red for errors but keep the brand logo
    final assetPath = _getPlatformAsset(embedType);
    const errorColor = Color(0xFFD32F2F);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Handled by library's GestureDetector
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: errorColor.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle Error Ring
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: 1.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            errorColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // Icon Container (Brand logo with error overlay or tinted)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: errorColor.withValues(alpha: 0.05),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Stack(
                          children: [
                            if (assetPath != null)
                              Opacity(
                                opacity: 0.3,
                                child: SvgPicture.asset(
                                  assetPath,
                                  colorFilter: ColorFilter.mode(
                                    errorColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            const Center(
                              child: Icon(
                                Icons.error_outline_rounded,
                                color: errorColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load content',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: errorColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to try again',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
