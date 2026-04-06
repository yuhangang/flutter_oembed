import 'package:flutter_embed/src/models/base_embed_params.dart';

/// Typed parameters for Meta platform (Facebook, Instagram, and Threads) oEmbed requests.
///
/// See:
/// - Facebook Page: https://graph.facebook.com/v22.0/oembed_page
/// - Facebook Post: https://graph.facebook.com/v22.0/oembed_post
/// - Facebook Video: https://graph.facebook.com/v22.0/oembed_video
/// - Instagram: https://graph.facebook.com/v22.0/instagram_oembed
/// - Threads: https://graph.threads.net/v1.0/oembed
class MetaEmbedParams extends BaseEmbedParams {
  const MetaEmbedParams({
    this.adaptContainerWidth,
    this.hideCover,
    this.hidecaption,
    this.maxheight,
    this.maxwidth,
    this.omitscript,
    this.sdklocale,
    this.showFacepile,
    this.showPosts,
    this.smallHeader,
    this.useiframe,
  });

  /// Factory constructor for Facebook Page Plugin parameters.
  factory MetaEmbedParams.facebookPage({
    bool? adaptContainerWidth,
    bool? hideCover,
    int? maxheight,
    int? maxwidth,
    bool? omitscript,
    String? sdklocale,
    bool? showFacepile,
    bool? showPosts,
    bool? smallHeader,
  }) =>
      MetaEmbedParams(
        adaptContainerWidth: adaptContainerWidth,
        hideCover: hideCover,
        maxheight: maxheight,
        maxwidth: maxwidth,
        omitscript: omitscript,
        sdklocale: sdklocale,
        showFacepile: showFacepile,
        showPosts: showPosts,
        smallHeader: smallHeader,
      );

  /// Factory constructor for Facebook Post parameters.
  factory MetaEmbedParams.facebookPost({
    int? maxwidth,
    bool? omitscript,
    String? sdklocale,
    bool? useiframe,
  }) =>
      MetaEmbedParams(
        maxwidth: maxwidth,
        omitscript: omitscript,
        sdklocale: sdklocale,
        useiframe: useiframe,
      );

  /// Factory constructor for Facebook Video parameters.
  factory MetaEmbedParams.facebookVideo({
    int? maxwidth,
    bool? omitscript,
    String? sdklocale,
    bool? useiframe,
  }) =>
      MetaEmbedParams(
        maxwidth: maxwidth,
        omitscript: omitscript,
        sdklocale: sdklocale,
        useiframe: useiframe,
      );

  /// Factory constructor for Instagram parameters.
  factory MetaEmbedParams.instagram({
    bool? hidecaption,
    int? maxwidth,
    bool? omitscript,
    String? sdklocale,
  }) =>
      MetaEmbedParams(
        hidecaption: hidecaption,
        maxwidth: maxwidth,
        omitscript: omitscript,
        sdklocale: sdklocale,
      );

  /// Factory constructor for Threads parameters.
  factory MetaEmbedParams.threads({
    bool? hidecaption,
    int? maxwidth,
    bool? omitscript,
    String? sdklocale,
  }) =>
      MetaEmbedParams(
        hidecaption: hidecaption,
        maxwidth: maxwidth,
        omitscript: omitscript,
        sdklocale: sdklocale,
      );

  /// (Facebook Page Plugin) Try to fit inside the container width. Default is true.
  final bool? adaptContainerWidth;

  /// (Facebook Page Plugin) Hide cover photo in the header. Default is false.
  final bool? hideCover;

  /// (Instagram & Threads) Hides the caption. Default is false.
  final bool? hidecaption;

  /// Maximum height of returned media.
  final int? maxheight;

  /// Maximum width of returned media.
  final int? maxwidth;

  /// If set to true, the returned embed HTML code will not include any javascript.
  final bool? omitscript;

  ///sdklocale. e.g. 'en_US'
  final String? sdklocale;

  /// (Facebook Page Plugin) Show profile photos when friends like this. Default is true.
  final bool? showFacepile;

  /// (Facebook Page Plugin) show_posts. Default is true.
  final bool? showPosts;

  /// (Facebook Page Plugin) Use the small header instead. Default is false.
  final bool? smallHeader;

  /// (Facebook Post & Video) useiframe. Default is false.
  final bool? useiframe;

  /// Converts the parameters to a map of strings for query parameters.
  @override
  Map<String, String> toMap() {
    return {
      if (adaptContainerWidth != null)
        'adapt_container_width': adaptContainerWidth.toString(),
      if (hideCover != null) 'hide_cover': hideCover.toString(),
      if (hidecaption != null) 'hidecaption': hidecaption.toString(),
      if (maxheight != null) 'maxheight': maxheight.toString(),
      if (maxwidth != null) 'maxwidth': maxwidth.toString(),
      if (omitscript != null) 'omitscript': omitscript.toString(),
      if (sdklocale != null) 'sdklocale': sdklocale!,
      if (showFacepile != null) 'show_facepile': showFacepile.toString(),
      if (showPosts != null) 'show_posts': showPosts.toString(),
      if (smallHeader != null) 'small_header': smallHeader.toString(),
      if (useiframe != null) 'useiframe': useiframe.toString(),
    };
  }

  @override
  List<Object?> get props => [
        adaptContainerWidth,
        hideCover,
        hidecaption,
        maxheight,
        maxwidth,
        omitscript,
        sdklocale,
        showFacepile,
        showPosts,
        smallHeader,
        useiframe,
      ];
}
