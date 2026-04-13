import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/widgets/embed_surface.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';

/// A standalone player widget for TikTok's native embedded player (v1).
///
/// Unlike the standard [EmbedCard] which relies on the oEmbed API or standard
/// iframe fallbacks, this uses the `tiktok.com/player/v1/` endpoint which
/// supports advanced customization.
import 'package:flutter_oembed/src/models/tiktok_embed_params.dart';

class TikTokEmbedPlayer extends StatefulWidget {
  /// The TikTok video URL or video ID.
  final String videoIdOrUrl;

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

  /// Automatically play the video when loaded. Defaults to false.
  final bool autoplay;

  /// Play the current video repeatedly. Defaults to false.
  final bool loop;

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

  /// The maximum width of the embed surface.
  final double? maxWidth;

  /// Aspect ratio for the embed. TikTok videos are usually 9:16.
  final double aspectRatio;

  /// Optional constraints for the player height.
  final EmbedConstraints? embedConstraints;

  /// Parameters for the native player. If provided, they override the
  /// individual parameters below.
  final TikTokEmbedParams? embedParams;

  const TikTokEmbedPlayer({
    super.key,
    required this.videoIdOrUrl,
    this.controls = true,
    this.progressBar = true,
    this.playButton = true,
    this.volumeControl = true,
    this.fullscreenButton = true,
    this.timestamp = true,
    this.autoplay = false,
    this.loop = false,
    this.musicInfo = false,
    this.description = false,
    this.rel = true,
    this.nativeContextMenu = true,
    this.closedCaption = true,
    this.muted = false,
    this.maxWidth,
    this.aspectRatio = 9 / 16,
    this.embedConstraints,
    this.embedParams,
    this.controller,
  });

  /// Optional controller to manage the player state.
  final EmbedController? controller;

  @override
  State<TikTokEmbedPlayer> createState() => _TikTokEmbedPlayerState();
}

class _TikTokEmbedPlayerState extends State<TikTokEmbedPlayer> {
  late EmbedController _controller;
  bool _isControllerInternal = false;
  late final SocialEmbedParam _param;

  @override
  void initState() {
    super.initState();
    final videoId = _extractTikTokVideoId(widget.videoIdOrUrl);

    // We construct a mock URL for the param, even if we are fetching by ID.
    final mockUrl = 'https://www.tiktok.com/@user/video/$videoId';

    _param = SocialEmbedParam(
      url: mockUrl,
      embedType: EmbedType.tiktok_v1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initControllerIfNeeded();
  }

  @override
  void didUpdateWidget(TikTokEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_isControllerInternal) {
        _controller.dispose();
      }

      if (widget.controller != null) {
        _controller = widget.controller!;
        _isControllerInternal = false;
      } else {
        _controller = EmbedController(
          param: _param,
          config: EmbedScope.configOf(context),
        );
        _isControllerInternal = true;
      }
    }
  }

  void _initControllerIfNeeded() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isControllerInternal = false;
    } else {
      _controller = EmbedController(
        param: _param,
        config: EmbedScope.configOf(context),
      );
      _isControllerInternal = true;
    }
  }

  @override
  void dispose() {
    if (_isControllerInternal) {
      _controller.dispose();
    }
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

    final params = widget.embedParams ??
        TikTokEmbedParams(
          controls: widget.controls,
          progressBar: widget.progressBar,
          playButton: widget.playButton,
          volumeControl: widget.volumeControl,
          fullscreenButton: widget.fullscreenButton,
          timestamp: widget.timestamp,
          autoplay: widget.autoplay,
          loop: widget.loop,
          musicInfo: widget.musicInfo,
          description: widget.description,
          rel: widget.rel,
          nativeContextMenu: widget.nativeContextMenu,
          closedCaption: widget.closedCaption,
          muted: widget.muted,
        );

    queryParams.addAll(params.toMap());

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
        final player = EmbedWebView.data(
          param: _param,
          data: EmbedData(html: playerUrl),
          maxWidth: widget.maxWidth ?? double.infinity,
          controller: _controller,
          style: style,
          embedConstraints: widget.embedConstraints,
        );

        if (widget.embedConstraints?.preferredHeight != null) {
          return player;
        }

        return AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: player,
        );
      },
    );
  }
}
