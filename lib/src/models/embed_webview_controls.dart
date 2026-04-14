import 'package:webview_flutter/webview_flutter.dart';

/// A set of controls exposed to the `webViewBuilder` of an embed widget.
///
/// This provides access to the underlying [WebViewController] and convenience
/// methods for media playback and embed lifecycle management.
class EmbedWebViewControls {
  /// The underlying [WebViewController] for the embed.
  final WebViewController controller;

  /// Callback to reload the embed content.
  final Future<void> Function() _onReload;

  /// Callback to trigger a manual height update of the embed.
  final Future<void> Function() _onUpdateHeight;

  /// Callback to pause any active media in the embed.
  final Future<void> Function() _onPause;

  /// Callback to resume any paused media in the embed.
  final Future<void> Function() _onResume;

  /// Callback to mute any active media in the embed.
  final Future<void> Function() _onMute;

  /// Callback to unmute any paused media in the embed.
  final Future<void> Function() _onUnmute;

  const EmbedWebViewControls({
    required this.controller,
    required Future<void> Function() onReload,
    required Future<void> Function() onUpdateHeight,
    required Future<void> Function() onPause,
    required Future<void> Function() onResume,
    required Future<void> Function() onMute,
    required Future<void> Function() onUnmute,
  })  : _onReload = onReload,
        _onUpdateHeight = onUpdateHeight,
        _onPause = onPause,
        _onResume = onResume,
        _onMute = onMute,
        _onUnmute = onUnmute;

  /// Reloads the embed content.
  Future<void> reload() => _onReload();

  /// Triggers a manual update of the embed's rendered height.
  ///
  /// This is useful if the content inside the WebView changes its height
  /// dynamically without notifying the host application.
  Future<void> updateHeight() => _onUpdateHeight();

  /// Requests the embed to pause any active media playback.
  ///
  /// This is a best-effort call as not all providers support programmatic
  /// media control.
  Future<void> pauseMedia() => _onPause();

  /// Requests the embed to resume any paused media playback.
  ///
  /// This is a best-effort call as not all providers support programmatic
  /// media control.
  Future<void> resumeMedia() => _onResume();

  /// Requests the embed to mute any active media playback.
  Future<void> muteMedia() => _onMute();

  /// Requests the embed to unmute any paused media playback.
  Future<void> unmuteMedia() => _onUnmute();
}
