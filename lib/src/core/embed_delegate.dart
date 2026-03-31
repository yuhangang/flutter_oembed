import 'package:flutter/material.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';

/// **Deprecated.** Use [EmbedConfig] and [EmbedStyle] instead.
///
/// Migration guide:
/// - `facebookAppId` / `facebookClientToken` → [EmbedConfig.facebookAppId] / [EmbedConfig.facebookClientToken]
/// - `onLinkTap` / `openSocialEmbedLinkClick` → [EmbedConfig.onLinkTap]
/// - Visual builders → [EmbedStyle.loadingBuilder] / [EmbedStyle.errorBuilder] / [EmbedStyle.footerBuilder]
/// - `getAppBrightness` / `scaffoldBackgroundColor` → Theme your app with Flutter's built-in theming.
@Deprecated(
  'EmbedDelegate is deprecated. Use EmbedConfig + EmbedStyle instead. '
  'See https://github.com/yuhangang/flutter_oembed for migration guide.'
)
abstract class EmbedDelegate {
  Future<void> openSocialEmbedLinkClick({
    required String url,
    required String embedType,
    required String location,
    required String source,
  });

  /// Check internet connection immediately
  bool checkConnection();

  /// Check if the webview should be shown for the given pageIdentifier and url
  bool showSocialEmbed(String pageIdentifier, String url);

  /// Check if the init embed should post to the coordinator
  void initEmbedPost(String url);

  /// Get Locale Language Code
  String getLocaleLanguageCode();

  /// Get App Brightness
  Brightness getAppBrightness();
  
  double get offlineToastOffset;
  String get facebookAppId;
  String get facebookClientToken;

  /// Get UI colors
  Color scaffoldBackgroundColor(BuildContext context);
  Color cardColor(BuildContext context);

  /// Builder for YouTube Video Card allowing the host app to provide its own implementation
  Widget buildYoutubeVideoCard({
    required BuildContext context,
    required SocialEmbedParam param,
    required String source,
  });

  /// Builder for Social Embed Refresh Placeholder
  Widget buildSocialEmbedRefreshPlaceholder({
    required BuildContext context,
    required SocialEmbedParam param,
    required VoidCallback onTap,
  });

  /// Builder for Social Embed Error Placeholder
  Widget buildSocialEmbedErrorPlaceholder({
    required BuildContext context,
    required SocialEmbedParam param,
    Exception? error,
  });

  /// Builder for Social Embed Load Button
  Widget buildSocialEmbedLoadButton({
    required BuildContext context,
    required SocialEmbedParam param,
    required String identifier,
  });

  /// Builder for Social Embed Link Wrapper
  Widget buildSocialEmbedLinkWrapper({
    required BuildContext context,
    required SocialEmbedParam param,
    required Widget child,
  });

  /// Builder for Social Embed Placeholder (Loading state)
  Widget buildSocialEmbedPlaceholder({
    required BuildContext context,
    required EmbedType embedType,
  });
}
