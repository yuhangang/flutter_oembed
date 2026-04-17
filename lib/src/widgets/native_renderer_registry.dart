import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/models/core/embed_constraints.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/models/params/tiktok_embed_params.dart';
import 'package:flutter_oembed/src/models/params/youtube_embed_params.dart';
import 'package:flutter_oembed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_oembed/src/widgets/youtube_embed_player.dart';

typedef NativeWidgetBuilder = Widget Function(
  BuildContext context,
  EmbedProviderContext embedContext,
  double maxWidth,
  EmbedController controller,
  EmbedConstraints? embedConstraints,
);

/// A registry that maps native renderer identifiers to their corresponding Flutter widget builders.
///
/// This registry decouples the core provider strategies from the specific UI implementations.
class NativeRendererRegistry {
  static final Map<String, NativeWidgetBuilder> _builders = {
    'youtube': (context, embedContext, maxWidth, controller, embedConstraints) {
      final params = embedContext.embedParams as YoutubeEmbedParams?;
      return YoutubeEmbedPlayer(
        videoIdOrUrl: embedContext.url,
        maxWidth: maxWidth,
        embedConstraints: embedConstraints,
        controls: params?.controls ?? true,
        autoplay: params?.autoplay ?? false,
        loop: params?.loop ?? false,
        rel: params?.rel ?? false,
        theme: params?.theme,
        color: params?.color,
        controller: controller,
      );
    },
    'tiktok': (context, embedContext, maxWidth, controller, embedConstraints) {
      return TikTokEmbedPlayer(
        videoIdOrUrl: embedContext.url,
        maxWidth: maxWidth,
        embedConstraints: embedConstraints,
        embedParams: embedContext.embedParams as TikTokEmbedParams?,
        controller: controller,
      );
    },
  };

  /// Builds a native widget for the given [identifier].
  ///
  /// Returns a [SizedBox.shrink] if no builder is registered for the identifier.
  static Widget build(
    String identifier,
    BuildContext context,
    EmbedProviderContext embedContext,
    double maxWidth,
    EmbedController controller,
    EmbedConstraints? embedConstraints,
  ) {
    final builder = _builders[identifier];
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return builder(
      context,
      embedContext,
      maxWidth,
      controller,
      embedConstraints,
    );
  }
}
