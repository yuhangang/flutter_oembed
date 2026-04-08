import 'package:flutter_oembed/src/models/base_embed_params.dart';

/// Typed parameters for Vimeo oEmbed requests.
///
/// See: https://developer.vimeo.com/api/oembed/videos
class VimeoEmbedParams extends BaseEmbedParams {
  const VimeoEmbedParams({
    this.autoplay,
    this.loop,
    this.muted,
    this.color,
    this.controls,
    this.dnt,
    this.title,
    this.byline,
    this.portrait,
    this.pip,
    this.quality,
    this.speed,
    this.transparent,
    this.responsive,
    this.autopause,
  });

  /// Automatically start playback of the video.
  final bool? autoplay;

  /// Set the video to loop.
  final bool? loop;

  /// Set the video to mute on load.
  final bool? muted;

  /// Specify the color of the video controls (hex code, e.g., '00adef').
  final String? color;

  /// Hide or reveal all player elements (playbar, sharing buttons, etc.).
  final bool? controls;

  /// Block the player from collecting session data and analytics (Do Not Track).
  final bool? dnt;

  /// Show or hide the video title.
  final bool? title;

  /// Show or hide the author's byline.
  final bool? byline;

  /// Show or hide the author's portrait.
  final bool? portrait;

  /// Show or hide the picture-in-picture button.
  final bool? pip;

  /// Set the default quality (e.g., '4k', '1080p', '720p', '360p').
  final String? quality;

  /// The playback speed of the video.
  final double? speed;

  /// Whether the player background is transparent.
  final bool? transparent;

  /// Whether the player should be responsive.
  final bool? responsive;

  /// Whether to pause the video when another one starts playing.
  final bool? autopause;

  /// Converts the parameters to a map of strings for query parameters.
  @override
  Map<String, String> toMap() {
    return {
      if (autoplay != null) 'autoplay': autoplay.toString(),
      if (loop != null) 'loop': loop.toString(),
      if (muted != null) 'muted': muted.toString(),
      if (color != null) 'color': color!,
      if (controls != null) 'controls': controls.toString(),
      if (dnt != null) 'dnt': dnt.toString(),
      if (title != null) 'title': title.toString(),
      if (byline != null) 'byline': byline.toString(),
      if (portrait != null) 'portrait': portrait.toString(),
      if (pip != null) 'pip': pip.toString(),
      if (quality != null) 'quality': quality!,
      if (speed != null) 'speed': speed.toString(),
      if (transparent != null) 'transparent': transparent.toString(),
      if (responsive != null) 'responsive': responsive.toString(),
      if (autopause != null) 'autopause': autopause.toString(),
    };
  }

  @override
  List<Object?> get props => [
        autoplay,
        loop,
        muted,
        color,
        controls,
        dnt,
        title,
        byline,
        portrait,
        pip,
        quality,
        speed,
        transparent,
        responsive,
        autopause,
      ];
}
