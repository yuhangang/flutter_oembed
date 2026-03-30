import 'package:flutter/material.dart';
import 'package:oembed/src/controllers/embed_controller.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:oembed/src/widgets/embed_webview.dart';
import 'package:oembed/src/widgets/embed_surface.dart';
import 'package:oembed/src/core/oembed_scope.dart';
import 'package:oembed/src/models/oembed_config.dart';
import 'package:oembed/src/models/oembed_data.dart';

/// A standalone player widget for YouTube's native iframe player.
///
/// **Note**: This widget is intended for simple use cases only (e.g., displaying
/// a basic video without complex interaction limits). If you need full control
/// over the player state, custom overlays, or want to interact deeply with the
/// YouTube IFrame Player API, we strongly recommend using dedicated community
/// packages like [youtube_player_iframe].
///
/// See: https://developers.google.com/youtube/iframe_api_reference
class YoutubeEmbedPlayer extends StatefulWidget {
  /// The YouTube video URL or video ID.
  /// (e.g. 'https://www.youtube.com/watch?v=9bZkp7q19f0' or '9bZkp7q19f0')
  final String videoIdOrUrl;

  /// Display the video player controls. Defaults to true.
  final bool controls;

  /// Automatically play the video when loaded. Defaults to false.
  final bool autoplay;

  /// Play the current video repeatedly. Defaults to false.
  final bool loop;

  /// Whether to show related videos at the end of the video. Defaults to false.
  final bool rel;

  /// The maximum width of the embed surface.
  final double? maxWidth;

  /// Aspect ratio for the embed. YouTube videos are generally 16:9.
  final double aspectRatio;

  const YoutubeEmbedPlayer({
    super.key,
    required this.videoIdOrUrl,
    this.controls = true,
    this.autoplay = false,
    this.loop = false,
    this.rel = false,
    this.maxWidth,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  late final EmbedController _controller;
  late final SocialEmbedParam _param;

  @override
  void initState() {
    super.initState();
    final videoId = _extractYoutubeVideoId(widget.videoIdOrUrl);
    
    // We construct a mock URL for the param, even if we are fetching by ID.
    final mockUrl = 'https://www.youtube.com/watch?v=$videoId';
    
    _param = SocialEmbedParam(
      url: mockUrl,
      embedType: EmbedType.youtube,
      source: 'YoutubePlayer',
      contentId: videoId,
      pageIdentifier: 'youtube_player_$videoId',
      elementId: null,
      extraIdentifier: '',
    );

    _controller = EmbedController(param: _param);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _extractYoutubeVideoId(String input) {
    if (!input.contains('http')) {
      return input; // Assume raw ID if no protocol is present
    }
    
    final uri = Uri.tryParse(input);
    if (uri == null) return input;

    if (uri.host.contains('youtube.com')) {
      if (uri.path == '/watch') {
        return uri.queryParameters['v'] ?? input;
      } else if (uri.path.startsWith('/embed/')) {
        return uri.pathSegments.last;
      } else if (uri.path.startsWith('/shorts/')) {
        return uri.pathSegments.last;
      }
    } else if (uri.host.contains('youtu.be')) {
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
    }
    
    return input; // Fallback
  }

  String _buildPlayerUrl(String videoId, {OembedConfig? config}) {
    var uri = Uri.parse('https://www.youtube.com/embed/$videoId');
    
    final queryParams = <String, String>{
      // Essential for avoiding Error 153 in embedded webviews
      'origin': 'https://www.youtube.com', 
      if (config != null) 'hl': config.locale,
      if (config != null) 'theme': config.brightness == Brightness.dark ? 'dark' : 'light',
    };
    
    if (!widget.controls) queryParams['controls'] = '0';
    if (widget.autoplay) queryParams['autoplay'] = '1';
    
    // For loop to work in the IFrame embed, the playlist parameter must be 
    // set to the same video ID.
    if (widget.loop) {
      queryParams['loop'] = '1';
      queryParams['playlist'] = videoId;
    }
    
    if (!widget.rel) {
      queryParams['rel'] = '0';
    }
    
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    final config = OembedScope.configOf(context);
    final style = config?.style ?? OembedScope.styleOf(context);
    final videoId = _extractYoutubeVideoId(widget.videoIdOrUrl);
    final playerUrl = _buildPlayerUrl(videoId, config: config);

    // Constructing a mock OembedData forces the controller to load an HTML
    // document rather than a top-level URL. This, combined with the origin query
    // and strict-origin referrer policy, fulfills YouTube's security requirements
    // and prevents Error 153 (Video Player Configuration Error).
    final iframeHtml =
        '<iframe width="100%" height="100%" src="$playerUrl" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>';

    final mockData = OembedData(
      html: iframeHtml,
      type: 'video',
      providerName: 'YouTube',
      providerUrl: 'https://www.youtube.com/',
    );

    // Using AspectRatio to maintain the standard 16:9 bounds natively
    return EmbedSurface(
      style: style,
      footerUrl: _param.url,
      childBuilder: (context) {
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: EmbedWebView.data(
            param: _param,
            data: mockData,
            maxWidth: widget.maxWidth ?? double.infinity,
            controller: _controller,
          ),
        );
      },
    );
  }
}
