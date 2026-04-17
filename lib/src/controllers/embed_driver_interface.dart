import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interface for embed drivers that manage low-level renderer interactions.
abstract class IEmbedDriver {
  /// The underlying [WebViewController].
  WebViewController get webViewController;

  /// The high-level [EmbedController].
  EmbedController get controller;

  /// Pauses any media playback.
  Future<void> pauseMedias({String reason});

  /// Resumes media playback.
  Future<void> resumeMedias({String reason});

  /// Mutes audio.
  Future<void> muteMedias({String reason});

  /// Unmutes audio.
  Future<void> unmuteMedias({String reason});

  /// Finalizes page loading behavior.
  Future<void> finalizePageFinished();

  /// Disposes of the driver resources.
  void dispose({bool preserveWebView});
}
