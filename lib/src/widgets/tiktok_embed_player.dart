import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
import 'package:flutter_embed/src/widgets/embed_surface.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/models/embed_config.dart';

/// A standalone player widget for TikTok's native embedded player (v1).
///
/// Unlike the standard [EmbedCard] which relies on the oEmbed API or standard
/// iframe fallbacks, this uses the `tiktok.com/player/v1/` endpoint which
/// supports advanced customization.
import 'package:flutter_embed/src/models/embed_tracking.dart';
import 'package:flutter_embed/src/models/tiktok_embed_params.dart';

class TikTokEmbedPlayer extends StatefulWidget {
  /// The TikTok video URL or video ID.
  final String videoIdOrUrl;

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

  /// The maximum width of the embed surface.
  final double? maxWidth;

  /// Aspect ratio for the embed. TikTok videos are usually 9:16.
  final double aspectRatio;

  /// Parameters for the native player. If provided, they override the
  /// individual parameters below.
  final TikTokEmbedParams? embedParams;

  const TikTokEmbedPlayer({
    super.key,
    required this.videoIdOrUrl,
    this.controls = true,
    this.autoplay = false,
    this.loop = false,
    this.musicInfo = false,
    this.description = false,
    this.maxWidth,
    this.aspectRatio = 9 / 16,
    this.embedParams,
  });

  @override
  State<TikTokEmbedPlayer> createState() => _TikTokEmbedPlayerState();
}

class _TikTokEmbedPlayerState extends State<TikTokEmbedPlayer> {
  EmbedController? _controller;
  late final SocialEmbedParam _param;

  @override
  void initState() {
    super.initState();
    final videoId = _extractTikTokVideoId(widget.videoIdOrUrl);

    // We construct a mock URL for the param, even if we are fetching by ID.
    final mockUrl = 'https://www.tiktok.com/@user/video/$videoId';

    _param = SocialEmbedParam(
      url: mockUrl,
      embedType: EmbedType.tiktok,
      tracking: EmbedTracking(
        source: 'TikTokPlayer',
        contentId: videoId,
        pageIdentifier: 'tiktok_player_$videoId',
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initControllerIfNeeded();
  }

  void _initControllerIfNeeded() {
    _controller ??= EmbedController(
      param: _param,
      delegate: EmbedScope.delegateOf(context),
      config: EmbedScope.configOf(context),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _extractTikTokVideoId(String input) {
    if (input.startsWith('http')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        final id = uri.pathSegments.lastWhere(
          (s) => int.tryParse(s) != null,
          orElse: () => '',
        );
        if (id.isNotEmpty) return id;
      }
    }
    // If it's just raw numeric ID, return it
    if (int.tryParse(input) != null) {
      return input;
    }
    return input; // Fallback
  }

  String _buildPlayerUrl(String videoId, {EmbedConfig? config}) {
    var uri = Uri.parse('https://www.tiktok.com/player/v1/$videoId');

    final queryParams = <String, String>{
      if (config != null) 'lang': config.locale,
    };
    final params = widget.embedParams;

    if (params != null) {
      if (!params.controls) queryParams['controls'] = '0';
      if (params.autoplay) queryParams['autoplay'] = '1';
      if (params.loop) queryParams['loop'] = '1';
      if (params.musicInfo) queryParams['music_info'] = '1';
      if (params.description) queryParams['description'] = '1';
    } else {
      if (!widget.controls) queryParams['controls'] = '0';
      if (widget.autoplay) queryParams['autoplay'] = '1';
      if (widget.loop) queryParams['loop'] = '1';
      if (widget.musicInfo) queryParams['music_info'] = '1';
      if (widget.description) queryParams['description'] = '1';
    }

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    final config = EmbedScope.configOf(context);
    final style = config?.style ?? EmbedScope.styleOf(context);
    final videoId = _extractTikTokVideoId(widget.videoIdOrUrl);
    final playerUrl = _buildPlayerUrl(videoId, config: config);

    // Using AspectRatio since the native player often requires fixed bounds
    return EmbedSurface(
      style: style,
      footerUrl: _param.url,
      childBuilder: (context) {
        if (_controller == null) return const SizedBox.shrink();
        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: EmbedWebView.url(
            param: _param,
            url: playerUrl,
            maxWidth: widget.maxWidth ?? double.infinity,
            controller: _controller!,
            style: style,
          ),
        );
      },
    );
  }
}
