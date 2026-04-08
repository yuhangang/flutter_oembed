import 'package:flutter_oembed/src/models/base_embed_params.dart';

/// Typed parameters for SoundCloud oEmbed requests.
///
/// See: https://developers.soundcloud.com/docs/api/reference#oembed
class SoundCloudEmbedParams extends BaseEmbedParams {
  const SoundCloudEmbedParams({
    this.maxheight,
    this.color,
    this.autoPlay,
    this.showComments,
    this.callback,
  });

  /// The maximum height of the widget in pixels.
  /// Default is 166px for tracks and 450px for sets.
  final int? maxheight;

  /// The primary color of the widget as a hex triplet (e.g., 'ff0066').
  final String? color;

  /// Whether the widget plays on load.
  final bool? autoPlay;

  /// Whether the player displays timed comments.
  final bool? showComments;

  /// A function name for the JSONP callback.
  final String? callback;

  @override
  Map<String, String> toMap() {
    return {
      if (maxheight != null) 'maxheight': maxheight.toString(),
      if (color != null) 'color': color!,
      if (autoPlay != null) 'auto_play': autoPlay.toString(),
      if (showComments != null) 'show_comments': showComments.toString(),
      if (callback != null) 'callback': callback!,
    };
  }

  @override
  List<Object?> get props => [
        maxheight,
        color,
        autoPlay,
        showComments,
        callback,
      ];
}
