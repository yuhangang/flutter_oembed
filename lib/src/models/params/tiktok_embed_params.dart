import 'package:flutter_oembed/src/models/params/base_embed_params.dart';

/// Parameters for TikTok's native embedded player (v1).
class TikTokEmbedParams extends BaseEmbedParams {
  /// Display the progress bar and all control buttons. Defaults to true.
  final bool controls;

  /// Display the progress bar. Defaults to true.
  final bool progressBar;

  /// Display the play button. Defaults to true.
  final bool playButton;

  /// Display the volume control button. Defaults to true.
  final bool volumeControl;

  /// Display the fullscreen button. Defaults to true.
  final bool fullscreenButton;

  /// Display the video's current playback time and duration. Defaults to true.
  final bool timestamp;

  /// Play the current video repeatedly. Defaults to false.
  final bool loop;

  /// Automatically play the video when the player loads. Defaults to false.
  final bool autoplay;

  /// Display the music info. Defaults to false.
  final bool musicInfo;

  /// Display the video description. Defaults to false.
  final bool description;

  /// Show recommended videos (true) or author's videos (false). Defaults to true.
  final bool rel;

  /// Display the browser's native context menu. Defaults to true.
  final bool nativeContextMenu;

  /// Display the closed caption icon. Defaults to true.
  final bool closedCaption;

  /// Set the default volume to 0 and prevent volume changes. Defaults to false.
  final bool muted;

  /// Whether to use the native v1 player instead of standard oEmbed.
  /// Defaults to false.
  final bool useV1Player;

  const TikTokEmbedParams({
    this.controls = true,
    this.progressBar = true,
    this.playButton = true,
    this.volumeControl = true,
    this.fullscreenButton = true,
    this.timestamp = true,
    this.loop = false,
    this.autoplay = false,
    this.musicInfo = false,
    this.description = false,
    this.rel = true,
    this.nativeContextMenu = true,
    this.closedCaption = true,
    this.muted = false,
    this.useV1Player = false,
  });

  @override
  Map<String, String> toMap() {
    return {
      'controls': controls ? '1' : '0',
      'progress_bar': progressBar ? '1' : '0',
      'play_button': playButton ? '1' : '0',
      'volume_control': volumeControl ? '1' : '0',
      'fullscreen_button': fullscreenButton ? '1' : '0',
      'timestamp': timestamp ? '1' : '0',
      'loop': loop ? '1' : '0',
      'autoplay': autoplay ? '1' : '0',
      'music_info': musicInfo ? '1' : '0',
      'description': description ? '1' : '0',
      'rel': rel ? '1' : '0',
      'native_context_menu': nativeContextMenu ? '1' : '0',
      'closed_caption': closedCaption ? '1' : '0',
      'muted': muted ? '1' : '0',
    };
  }

  TikTokEmbedParams copyWith({
    bool? controls,
    bool? progressBar,
    bool? playButton,
    bool? volumeControl,
    bool? fullscreenButton,
    bool? timestamp,
    bool? loop,
    bool? autoplay,
    bool? musicInfo,
    bool? description,
    bool? rel,
    bool? nativeContextMenu,
    bool? closedCaption,
    bool? muted,
    bool? useV1Player,
  }) {
    return TikTokEmbedParams(
      controls: controls ?? this.controls,
      progressBar: progressBar ?? this.progressBar,
      playButton: playButton ?? this.playButton,
      volumeControl: volumeControl ?? this.volumeControl,
      fullscreenButton: fullscreenButton ?? this.fullscreenButton,
      timestamp: timestamp ?? this.timestamp,
      loop: loop ?? this.loop,
      autoplay: autoplay ?? this.autoplay,
      musicInfo: musicInfo ?? this.musicInfo,
      description: description ?? this.description,
      rel: rel ?? this.rel,
      nativeContextMenu: nativeContextMenu ?? this.nativeContextMenu,
      closedCaption: closedCaption ?? this.closedCaption,
      muted: muted ?? this.muted,
      useV1Player: useV1Player ?? this.useV1Player,
    );
  }

  @override
  List<Object?> get props => [
        controls,
        progressBar,
        playButton,
        volumeControl,
        fullscreenButton,
        timestamp,
        loop,
        autoplay,
        musicInfo,
        description,
        rel,
        nativeContextMenu,
        closedCaption,
        muted,
        useV1Player,
      ];
}
