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

  /// Mutes media elements in the top-level document.
  Future<void> muteMediaElements() async {
    await runJavaScript(_muteMediaElementsScript);
  }

  /// Unmutes media elements in the top-level document.
  Future<void> unmuteMediaElements() async {
    await runJavaScript(_unmuteMediaElementsScript);
  }

  /// Pauses media elements in the top-level document.
  Future<void> pauseMediaElements() async {
    await runJavaScript(_pauseMediaElementsScript);
  }

  /// Attempts to resume paused media elements in the top-level document.
  ///
  /// Playback can still be blocked by provider autoplay policies.
  Future<void> resumeMediaElements() async {
    await runJavaScript(_resumeMediaElementsScript);
  }

  /// Seeks top-level media elements to the requested position in seconds.
  Future<void> seekMediaElementsTo(double seconds) async {
    await runJavaScript(_buildSeekMediaElementsScript(seconds));
  }

  /// Sends a JSON string message to matching iframe players via postMessage.
  Future<void> postJsonStringMessageToIframes({
    required List<String> srcFragments,
    required String messageJson,
  }) async {
    await runJavaScript(
      _buildIframePostMessageScript(
        srcFragments: srcFragments,
        messageExpression: _wrapJavaScriptStringLiteral(messageJson),
      ),
    );
  }

  /// Sends a JavaScript object or expression to matching iframe players via
  /// postMessage.
  Future<void> postJavaScriptMessageToIframes({
    required List<String> srcFragments,
    required String messageExpression,
  }) async {
    await runJavaScript(
      _buildIframePostMessageScript(
        srcFragments: srcFragments,
        messageExpression: messageExpression,
      ),
    );
  }
}

const _muteMediaElementsScript = """
document.querySelectorAll('video, audio').forEach(media => {
  try { media.muted = true; } catch (e) {}
});
""";

const _unmuteMediaElementsScript = """
document.querySelectorAll('video, audio').forEach(media => {
  try { media.muted = false; } catch (e) {}
});
""";

const _pauseMediaElementsScript = """
document.querySelectorAll('video, audio').forEach(media => {
  try { media.pause(); } catch (e) {}
});
""";

const _resumeMediaElementsScript = """
document.querySelectorAll('video, audio').forEach(media => {
  try { media.play?.(); } catch (e) {}
});
""";

String _buildSeekMediaElementsScript(double seconds) => """
document.querySelectorAll('video, audio').forEach(media => {
  try { media.currentTime = $seconds; } catch (e) {}
});
""";

String _buildIframePostMessageScript({
  required List<String> srcFragments,
  required String messageExpression,
}) {
  final fragments = srcFragments.map(_wrapJavaScriptStringLiteral).join(', ');

  return """
(function() {
  var fragments = [$fragments];
  var currentHref = (window.location && window.location.href) || '';
  var currentMatches = false;
  for (var i = 0; i < fragments.length; i += 1) {
    if (currentHref.indexOf(fragments[i]) !== -1) {
      currentMatches = true;
      break;
    }
  }
  if (currentMatches) {
    try {
      if (window.postMessage) {
        window.postMessage($messageExpression, '*');
      }
    } catch (e) {}
  }
  var iframes = document.querySelectorAll('iframe');
  for (var iframeIndex = 0; iframeIndex < iframes.length; iframeIndex += 1) {
    var iframe = iframes[iframeIndex];
    var src = iframe.src || '';
    var matches = false;
    for (var fragmentIndex = 0;
        fragmentIndex < fragments.length;
        fragmentIndex += 1) {
      if (src.indexOf(fragments[fragmentIndex]) !== -1) {
        matches = true;
        break;
      }
    }
    if (!matches) {
      continue;
    }
    try {
      if (iframe.contentWindow && iframe.contentWindow.postMessage) {
        iframe.contentWindow.postMessage($messageExpression, '*');
      }
    } catch (e) {}
  }
})();
""";
}

String _wrapJavaScriptStringLiteral(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return "'$escaped'";
}
