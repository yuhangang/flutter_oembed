import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:embed_example/utils/url_launcher_utils.dart';
import 'package:embed_example/pages/home_page.dart';
import 'package:embed_example/widgets/embed_placeholder.dart';

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
    return EmbedScope(
      config: EmbedConfig(
        providers: EmbedProviderConfig(
          // Only allow these providers (comment out to enable all)
          // enabledProviders: {'YouTube', 'Spotify', 'Vimeo', 'TikTok', 'SoundCloud'},
          providerRenderModes: {
            // Use iframe mode for YouTube & Spotify (skips OEmbed API)
            'YouTube': EmbedRenderMode.iframe,
            'Spotify': EmbedRenderMode.iframe,
          },
        ),
        cache: const EmbedCacheConfig(
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
        style: EmbedStyle(
          errorBuilder: (context, error) {
            return const SocialEmbedErrorPlaceholder(
              embedType: EmbedType.other,
            );
          },
        ),
        logger: const EmbedLogger.enabled(),
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
