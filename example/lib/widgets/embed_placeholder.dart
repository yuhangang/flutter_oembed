import 'package:flutter/material.dart';
import 'package:flutter_embed/flutter_embed.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:embed_example/utils/platform_utils.dart';

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
    final assetPath = getPlatformAsset(widget.embedType);

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
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
                              ? (assetPath.endsWith('.png')
                                  ? Image.asset(assetPath, fit: BoxFit.contain)
                                  : SvgPicture.asset(
                                    assetPath,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).iconTheme.color!,
                                      BlendMode.srcIn,
                                    ),
                                  ))
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
      case EmbedType.tiktok_v1:
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
      case EmbedType.giphy:
        return _PlatformTheme(
          primaryColor: Colors.black,
          gradient: const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF616161)],
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
    final assetPath = getPlatformAsset(embedType);
    const errorColor = Color(0xFFD32F2F);

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Handled by library's GestureDetector
          borderRadius:
              embedType.isVideo ? BorderRadius.zero : BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  embedType.isVideo
                      ? BorderRadius.zero
                      : BorderRadius.circular(24),
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
                                child:
                                    assetPath.endsWith('.png')
                                        ? Image.asset(
                                          assetPath,
                                          fit: BoxFit.contain,
                                        )
                                        : SvgPicture.asset(
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
