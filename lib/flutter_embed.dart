/// A Flutter package for embedding social media content (X, TikTok, Instagram,
/// Facebook, YouTube, Spotify, Vimeo, and more) using the OEmbed protocol
/// with WebView rendering.
///
/// To get started, wrap your app in an [EmbedScope] and use the [EmbedCard] widget:
///
/// ```dart
/// EmbedScope(
///   config: EmbedConfig(...),
///   child: EmbedCard(url: 'https://twitter.com/x/status/123'),
/// )
/// ```
library;

// ============================================================
// flutter_oembed — Public API
// ============================================================
//
// Configuration & Scope
export 'src/core/embed_scope.dart';
export 'src/core/embed_delegate.dart';
export 'src/core/simple_embed_delegate.dart';
export 'src/logging/embed_logger.dart';
//
// Models
export 'src/models/embed_enums.dart';
export 'src/models/embed_cache_config.dart';
export 'src/models/embed_config.dart';
export 'src/models/embed_data.dart';
export 'src/models/embed_provider_config.dart';
export 'src/models/embed_style.dart';
export 'src/models/provider_rule.dart';
export 'src/models/social_embed_param.dart';
// Widgets (public entry points)
export 'src/widgets/embed_card.dart';
export 'src/widgets/embed_renderer.dart';
export 'src/widgets/tiktok_embed_player.dart';
export 'src/widgets/youtube_embed_player.dart';
//
// Controller (advanced use)
export 'src/controllers/embed_controller.dart';
//
// Utils
export 'src/utils/embed_type_extensions.dart';
//
// WebView re-exports (for custom navigation handlers)
export 'package:webview_flutter/webview_flutter.dart'
    show NavigationDecision, NavigationRequest;
