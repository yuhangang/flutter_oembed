import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_delegate.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';

/// A ready-to-use [EmbedDelegate] with sensible defaults.
///
/// Use this if you want to set up an embed with minimal boilerplate.
/// Override only the methods you care about.
///
/// For most cases, prefer using [EmbedConfig] via [EmbedScope] which
/// doesn't require a delegate at all.
///
/// ```dart
/// EmbedScope(
///   delegate: SimpleEmbedDelegate(
///     facebookAppId: 'YOUR_APP_ID',
///     facebookClientToken: 'YOUR_CLIENT_TOKEN',
///   ),
///   child: ...,
/// )
/// ```
class SimpleEmbedDelegate implements EmbedDelegate {
  const SimpleEmbedDelegate({
    this.facebookAppId = '',
    this.facebookClientToken = '',
    this.offlineToastOffset = 0,
    this.onLinkClick,
    this.connectionChecker,
    this.scaffoldBgColor,
    this.cardBgColor,
  });

  @override
  final String facebookAppId;

  @override
  final String facebookClientToken;

  @override
  final double offlineToastOffset;

  final void Function(
          String url, String embedType, String location, String source)?
      onLinkClick;
  final bool Function()? connectionChecker;
  final Color Function(BuildContext)? scaffoldBgColor;
  final Color Function(BuildContext)? cardBgColor;

  @override
  Future<void> openSocialEmbedLinkClick({
    required String url,
    required String embedType,
    required String location,
    required String source,
  }) async {
    onLinkClick?.call(url, embedType, location, source);
  }

  @override
  bool checkConnection() => connectionChecker?.call() ?? true;

  @override
  bool showSocialEmbed(String pageIdentifier, String url) => true;

  @override
  void initEmbedPost(String url) {}

  @override
  String getLocaleLanguageCode() => 'en';

  @override
  Brightness getAppBrightness() => Brightness.light;

  @override
  Color scaffoldBackgroundColor(BuildContext context) =>
      scaffoldBgColor?.call(context) ??
      Theme.of(context).scaffoldBackgroundColor;

  @override
  Color cardColor(BuildContext context) =>
      cardBgColor?.call(context) ?? Theme.of(context).cardColor;

  @override
  Widget buildYoutubeVideoCard({
    required BuildContext context,
    required SocialEmbedParam param,
    required String source,
  }) =>
      const SizedBox.shrink();

  @override
  Widget buildSocialEmbedRefreshPlaceholder({
    required BuildContext context,
    required SocialEmbedParam param,
    required VoidCallback onTap,
  }) =>
      AspectRatio(
        aspectRatio: 4 / 3,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
              borderRadius: param.embedType.isVideo 
                  ? BorderRadius.zero 
                  : BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).disabledColor,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget buildSocialEmbedErrorPlaceholder({
    required BuildContext context,
    required SocialEmbedParam param,
    Exception? error,
  }) =>
      AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.05),
            borderRadius: param.embedType.isVideo 
                ? BorderRadius.zero 
                : BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load content',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget buildSocialEmbedLoadButton({
    required BuildContext context,
    required SocialEmbedParam param,
    required String identifier,
  }) =>
      const SizedBox.shrink();

  @override
  Widget buildSocialEmbedLinkWrapper({
    required BuildContext context,
    required SocialEmbedParam param,
    required Widget child,
  }) =>
      child;

  @override
  Widget buildSocialEmbedPlaceholder({
    required BuildContext context,
    required EmbedType embedType,
  }) =>
      AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.03),
            borderRadius: embedType.isVideo 
                ? BorderRadius.zero 
                : BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).disabledColor.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ),
      );
}
