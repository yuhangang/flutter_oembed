import 'package:flutter_embed/src/models/base_embed_params.dart';

/// Parameters for YouTube embeds.
///
/// See: https://developers.google.com/youtube/player_parameters
class YoutubeEmbedParams extends BaseEmbedParams {
  /// Display the video player controls. Defaults to true.
  final bool? controls;

  /// Automatically play the video when loaded. Defaults to false.
  final bool? autoplay;

  /// Play the current video repeatedly. Defaults to false.
  final bool? loop;

  /// Whether to show related videos at the end of the video. Defaults to false.
  final bool? rel;

  /// The player's color preference. Valid: 'red', 'white'.
  final String? color;

  /// The player's theme preference. Valid: 'dark', 'light'.
  final String? theme;

  const YoutubeEmbedParams({
    this.controls,
    this.autoplay,
    this.loop,
    this.rel,
    this.color,
    this.theme,
  });

  @override
  Map<String, String> toMap() {
    return {
      if (controls != null) 'controls': controls! ? '1' : '0',
      if (autoplay != null) 'autoplay': autoplay! ? '1' : '0',
      if (loop != null) 'loop': loop! ? '1' : '0',
      if (rel != null) 'rel': rel! ? '1' : '0',
      if (color != null) 'color': color!,
      if (theme != null) 'theme': theme!,
    };
  }

  YoutubeEmbedParams copyWith({
    bool? controls,
    bool? autoplay,
    bool? loop,
    bool? rel,
    String? color,
    String? theme,
  }) {
    return YoutubeEmbedParams(
      controls: controls ?? this.controls,
      autoplay: autoplay ?? this.autoplay,
      loop: loop ?? this.loop,
      rel: rel ?? this.rel,
      color: color ?? this.color,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [controls, autoplay, loop, rel, color, theme];
}
