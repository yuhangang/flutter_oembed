import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

WebViewController generateWebViewController() {
  late final PlatformWebViewControllerCreationParams webViewParams;

  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    webViewParams = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    webViewParams = const PlatformWebViewControllerCreationParams();
  }

  return WebViewController.fromPlatformCreationParams(
    webViewParams,
  );
}

extension EmbedWebviewControllerUtils on WebViewController {
  Future<double?> getEmbedDocumentHeight() async {
    final documentHeightQuery = await runJavaScriptReturningResult(
      'document.body.clientHeight;',
    );

    double? height = double.tryParse(
      (documentHeightQuery.toString()),
    );

    return height;
  }

  /// Called when user navigate to other page.
  ///
  /// It will mute all the audio in the embed post.
  Future<void> muteAudioWidget() async {
    await runJavaScript(_muteAudioWidgetScript);

    return;
  }

  /// Called when user navigate to other page.
  ///
  /// It will pause all the videos(if exists) in the embed post.
  /// If the embed post is not able to pause the videos,
  /// it will refresh the embed `iframe` to pause the videos.
  Future<void> pauseVideos() async {
    await runJavaScript(
      _pauseVideosScript,
    );
  }
}

const _muteAudioWidgetScript = """
var isMuted = false;

document.querySelectorAll('audio').forEach(v => {
  v.muted = true;
  isMuted = true;
  console.log("iframe audio");
});

if (isMuted === false){
try {
  document.querySelectorAll('iframe').forEach(f => { f.contentWindow.document.querySelectorAll('audio').forEach(v => {
   v.muted = true; isMuted = true;}); });
}
catch (e) {
}

}

""";

const _pauseVideosScript = """
var isPaused = false;
try {
  document.querySelectorAll('iframe').forEach(f => { f.contentWindow.document.querySelectorAll('video').forEach(v => { v.pause(); isPaused = true;}); });
}
catch (e) {
}

if (isPaused === false){
  document.querySelectorAll('video').forEach(v => { v.pause(); isPaused = true; });
}


if (isPaused === false){
  document.querySelectorAll('iframe').forEach(f => { f.src = f.src });
}
""";
