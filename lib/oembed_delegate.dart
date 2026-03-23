import 'package:flutter/material.dart';

abstract class OembedDelegate {
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
    required dynamic param,
    required String source,
  });

  /// Builder for Social Embed Refresh Placeholder
  Widget buildSocialEmbedRefreshPlaceholder({
    required BuildContext context,
    required dynamic param,
    required VoidCallback onTap,
  });

  /// Builder for Social Embed Error Placeholder
  Widget buildSocialEmbedErrorPlaceholder({
    required BuildContext context,
    required dynamic param,
    Exception? error,
  });

  /// Builder for Social Embed Load Button
  Widget buildSocialEmbedLoadButton({
    required BuildContext context,
    required dynamic param,
    required String identifier,
  });

  /// Builder for Social Embed Link Wrapper
  Widget buildSocialEmbedLinkWrapper({
    required BuildContext context,
    required dynamic param,
    required Widget child,
  });

  /// Builder for Social Embed Placeholder (Loading state)
  Widget buildSocialEmbedPlaceholder({
    required BuildContext context,
    required dynamic embedType,
  });
}
