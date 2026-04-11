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
      'Math.ceil(Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight));',
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
// 1. Mute top-level media
document.querySelectorAll('video, audio').forEach(media => {
  try { media.muted = true; } catch (e) {}
});

// 2. Safely mute iframes via postMessage to avoid CORS
document.querySelectorAll('iframe').forEach(iframe => {
  let src = iframe.src || '';
  try {
    if (src.includes('youtube.com') || src.includes('youtu.be')) {
      iframe.contentWindow.postMessage('{"event":"command","func":"mute","args":""}', '*');
    } else if (src.includes('vimeo.com')) {
      iframe.contentWindow.postMessage('{"method":"setVolume", "value": 0}', '*');
    }
  } catch (e) {}
});
""";

const _pauseVideosScript = """
// 1. Pause any direct <video> or <audio> tags in the main document (No CORS issue here)
document.querySelectorAll('video, audio').forEach(media => {
  try { 
    media.pause(); 
  } catch (e) {}
});

// 2. Safely interact with iframes using postMessage to avoid CORS errors
document.querySelectorAll('iframe').forEach(iframe => {
  let src = iframe.src || '';

  try {
    if (src.includes('youtube.com') || src.includes('youtu.be')) {
      iframe.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
    }
    else if (src.includes('vimeo.com')) {
      iframe.contentWindow.postMessage('{"method":"pause"}', '*');
    }
    else if (src.includes('spotify.com')) {
      iframe.contentWindow.postMessage('{"command":"pause"}', '*');
    }
    else if (src.includes('soundcloud.com')) {
      iframe.contentWindow.postMessage('{"method":"pause"}', '*');
    }
    else {
      // For social embeds (TikTok, Instagram, etc) that don't support postMessage,
      // we rely on their internal IntersectionObservers to auto-pause when hidden.
      // Uncommenting the below line would force reload them, causing loss of scroll state.
      // iframe.src = iframe.src; 
    }
  } catch (e) {
    console.error("Error messaging iframe:", e);
  }
});
""";
