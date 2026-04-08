import 'package:flutter_oembed/src/models/base_embed_params.dart';

/// Parameters for TikTok's native embedded player (v1).
class TikTokEmbedParams extends BaseEmbedParams {
  /// Display the progress bar and all control buttons. Defaults to true.
  final bool controls;

  /// Automatically play the video when loaded. Defaults to false.
  final bool autoplay;

  /// Play the current video repeatedly. Defaults to false.
  final bool loop;

  /// Display the music info. Defaults to false.
  final bool musicInfo;

  /// Display the video description. Defaults to false.
  final bool description;

  const TikTokEmbedParams({
    this.controls = true,
    this.autoplay = false,
    this.loop = false,
    this.musicInfo = true,
    this.description = true,
  });

  @override
  Map<String, String> toMap() {
    return {
      'controls': controls ? '1' : '0',
      'autoplay': autoplay ? '1' : '0',
      'loop': loop ? '1' : '0',
      'music_info': musicInfo ? '1' : '0',
      'description': description ? '1' : '0',
    };
  }

  TikTokEmbedParams copyWith({
    bool? controls,
    bool? autoplay,
    bool? loop,
    bool? musicInfo,
    bool? description,
  }) {
    return TikTokEmbedParams(
      controls: controls ?? this.controls,
      autoplay: autoplay ?? this.autoplay,
      loop: loop ?? this.loop,
      musicInfo: musicInfo ?? this.musicInfo,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [controls, autoplay, loop, musicInfo, description];
}
