import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/utils/embed_link_utils.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/widgets/embed_surface.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';

/// A standalone player widget for YouTube's native iframe player.
///
/// **Note**: This widget is intended for simple use cases only (e.g., displaying
/// a basic video without complex interaction limits). If you need full control
/// over the player state, custom overlays, or want to interact deeply with the
/// YouTube IFrame Player API, we strongly recommend using dedicated community
/// packages like [youtube_player_iframe].
///
/// See: https://developers.google.com/youtube/iframe_api_reference

const String kDefaultYoutubePlayerHost = 'https://www.youtube-nocookie.com';
const String kYoutubeNoCookiePlayerHost = 'https://www.youtube-nocookie.com';

String buildYoutubePlayerHtml({
  required String playerId,
  required String videoId,
  required String host,
  required Map<String, Object> playerVars,
}) {
  final encodedPlayerId = jsonEncode(playerId);
  final encodedVideoId = jsonEncode(videoId);
  final encodedHost = jsonEncode(host);
  final encodedPlayerVars = jsonEncode(playerVars);

  return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
    />
    <meta name="referrer" content="strict-origin-when-cross-origin">
    <style>
      html, body {
        margin: 0;
        width: 100%;
        height: 100%;
        overflow: hidden;
      }

      .embed-container {
        position: relative;
        width: 100%;
        height: 100%;
      }

      .embed-container iframe,
      .embed-container object,
      .embed-container embed {
        position: absolute;
        top: 0;
        left: 0;
        width: 100% !important;
        height: 100% !important;
      }
    </style>
    <title>YouTube Player</title>
  </head>
  <body>
    <div class="embed-container">
      <div id=$encodedPlayerId></div>
    </div>

    <script>
      var tag = document.createElement("script");
      tag.src = "https://www.youtube.com/iframe_api";
      var firstScriptTag = document.getElementsByTagName("script")[0];
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

      var player;

      function resizePlayer() {
        if (player && player.setSize) {
          player.setSize(window.innerWidth, window.innerHeight);
        }
      }

      function onYouTubeIframeAPIReady() {
        player = new YT.Player($encodedPlayerId, {
          host: $encodedHost,
          width: "100%",
          height: "100%",
          videoId: $encodedVideoId,
          playerVars: $encodedPlayerVars,
          events: {
            onReady: function () {
              resizePlayer();
            },
            onStateChange: function () {
              resizePlayer();
            }
          }
        });

        resizePlayer();
      }

      window.addEventListener("resize", resizePlayer);
    </script>
  </body>
</html>
''';
}

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

  /// IFrame host passed to the YouTube player API.
  final String host;

  /// Whether to include `playerVars.origin` in the generated player config.
  ///
  /// This is intentionally opt-in because the value should normally be the
  /// embedding page's real origin rather than a YouTube domain.
  final bool useOriginExperiment;

  /// Origin used when [useOriginExperiment] is enabled.
  final String experimentalOrigin;

  const YoutubeEmbedPlayer({
    super.key,
    required this.videoIdOrUrl,
    this.controls = true,
    this.autoplay = false,
    this.loop = false,
    this.rel = false,
    this.maxWidth,
    this.aspectRatio = 16 / 9,
    this.host = kDefaultYoutubePlayerHost,
    this.useOriginExperiment = false,
    this.experimentalOrigin = kYoutubeNoCookiePlayerHost,
    this.theme,
    this.color,
  });

  /// The player's theme preference. Valid: 'dark', 'light'.
  final String? theme;

  /// The player's color preference. Valid: 'red', 'white'.
  final String? color;

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  EmbedController? _controller;
  late final SocialEmbedParam _param;

  @override
  void initState() {
    super.initState();
    final videoId = _extractYoutubeVideoId(widget.videoIdOrUrl);

    // We construct a mock URL for the param, even if we are fetching by ID.
    final mockUrl = 'https://www.youtube.com/watch?v=$videoId';

    _param = SocialEmbedParam(url: mockUrl, embedType: EmbedType.youtube);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initControllerIfNeeded();
  }

  void _initControllerIfNeeded() {
    _controller ??= EmbedController(
      param: _param,
      config: EmbedScope.configOf(context),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _extractYoutubeVideoId(String input) {
    return getYoutubeVideoId(input) ?? input;
  }

  Map<String, Object> _buildPlayerVars(
    String videoId,
    String locale,
    Brightness brightness,
  ) {
    // We force origin to match the host we are using, which is now
    // https://www.youtube-nocookie.com. This is consistent with EmbedWebViewDriver.
    final effectiveOrigin = widget.host;
    final effectiveTheme =
        widget.theme ?? (brightness == Brightness.light ? 'light' : 'dark');

    return <String, Object>{
      'playsinline': 1,
      'controls': widget.controls ? 1 : 0,
      'autoplay': widget.autoplay ? 1 : 0,
      'mute': widget.autoplay ? 1 : 0,
      'enablejsapi': 1,
      'modestbranding': 1,
      'rel': widget.rel ? 1 : 0,
      'loop': widget.loop ? 1 : 0,
      'hl': locale,
      'theme': effectiveTheme,
      if (widget.color != null) 'color': widget.color!,
      'origin': effectiveOrigin,
      'widget_referrer': effectiveOrigin,
      if (widget.loop) 'playlist': videoId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = EmbedScope.configOf(context);
    final style = config?.style ?? EmbedScope.styleOf(context);
    final videoId = _extractYoutubeVideoId(widget.videoIdOrUrl);
    final playerHtml = buildYoutubePlayerHtml(
      playerId: 'youtube-player-$videoId',
      videoId: videoId,
      host: widget.host,
      playerVars: _buildPlayerVars(
        videoId,
        config?.locale ?? 'en',
        config?.brightness ?? Brightness.light,
      ),
    );

    final mockData = EmbedData(
      html: playerHtml,
      type: 'video',
      providerName: 'YouTube',
      providerUrl:
          widget.useOriginExperiment ? widget.experimentalOrigin : widget.host,
    );

    return EmbedSurface(
      style: style,
      footerUrl: _param.url,
      childBuilder: (context) {
        if (_controller == null) return const SizedBox.shrink();
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: EmbedWebView.data(
            param: _param,
            data: mockData,
            maxWidth: widget.maxWidth ?? double.infinity,
            controller: _controller!,
            style: style,
          ),
        );
      },
    );
  }
}
