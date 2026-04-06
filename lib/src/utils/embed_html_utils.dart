import 'package:flutter_embed/src/models/embed_enums.dart';

String loadEmbedHtmlDocument(
  String embedData, {
  required EmbedType type,
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  final csp = _getCspMetaTag(type);

  switch (type) {
    case EmbedType.x:
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      padding-bottom: 4px;
      $scrollStyles
    }
  </style>
</head>
<body>
  <div>
    $embedData
  </div>
  $_resizeObserverScript
</body>
</html>
''';
    // Currently not in used, as current using url to load TikTok embeds
    case EmbedType.tiktok:
    case EmbedType.tiktok_v1:
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width height=device-height">
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      padding-bottom: 24px;
      $scrollStyles
    }
    blockquote.tiktok-embed {
      margin: 0;
      padding: 0;
      width: 100% !important;
      max-width: ${maxWidth}px !important;
    }
  </style>
</head>
<body>
  <div style="display: flex; justify-content: center;">
    $embedData
  </div>
  <script>
    (function() {
      var checkTikTok = setInterval(function() {
        if (window.tiktok && window.tiktok.embed) {
          window.tiktok.embed();
          clearInterval(checkTikTok);
        }
      }, 100);
      setTimeout(function() { clearInterval(checkTikTok); }, 5000);
    })();
  </script>
  $_resizeObserverScript
</body>
</html>
''';

    case EmbedType.facebook:
    case EmbedType.facebook_video:
    case EmbedType.facebook_post:
      final isFacebookVideo = type == EmbedType.facebook_video;
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width:${maxWidth}px;
      ${!isFacebookVideo ? 'background-color: white;' : ''}
      $scrollStyles
    }
    iframe {
      width: ${maxWidth}px !important;
    }
  </style>
</head>
<body>
  $embedData
  $_resizeObserverScript
</body>
</html>
''';
    case EmbedType.instagram:
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      $scrollStyles
    }
  </style>
</head>
<body>
  $embedData
  $_resizeObserverScript
</body>
</html>
''';

    case EmbedType.youtube:
    case EmbedType.spotify:
    case EmbedType.vimeo:
    case EmbedType.dailymotion:
    case EmbedType.soundcloud:
    case EmbedType.threads:
    case EmbedType.giphy:
      final processedData = type == EmbedType.youtube
          ? _injectYoutubeSecurityHeaders(embedData)
          : embedData;
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  ${type == EmbedType.youtube ? '<meta name="referrer" content="strict-origin-when-cross-origin">' : ''}
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      $scrollStyles
    }
  </style>
</head>
<body>
  $processedData
  $_resizeObserverScript
</body>
</html>
''';

    case EmbedType.reddit:
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      $scrollStyles
    }
    #reddit-container {
      width: 100%;
      display: flex;
      justify-content: center;
    }
    blockquote.reddit-embed-bq {
      margin: 0 !important;
      width: 100% !important;
      max-width: ${maxWidth}px !important;
    }
  </style>
</head>
<body>
  <div id="reddit-container">
    $embedData
  </div>
  $_resizeObserverScript
</body>
</html>
''';

    case EmbedType.other:
      return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  $csp
  <style>
    html, body {
      margin: 0;
      padding: 0;
      $scrollStyles
    }
  </style>
</head>
<body>
  $embedData
  $_resizeObserverScript
</body>
</html>
''';
  }
}

String _injectYoutubeSecurityHeaders(String html) {
  if (!html.contains('youtube.com/embed/') &&
      !html.contains('youtube-nocookie.com/embed/')) {
    return html;
  }

  var processedHtml = html;

  // Add referrerpolicy if missing to the iframe itself
  if (!processedHtml.contains('referrerpolicy')) {
    processedHtml = processedHtml.replaceFirst(
      '<iframe',
      '<iframe referrerpolicy="strict-origin-when-cross-origin"',
    );
  }

  final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(processedHtml);
  if (srcMatch != null) {
    final currentSrc = srcMatch.group(1)!;
    final uri = Uri.tryParse(currentSrc);
    if (uri != null) {
      final params = Map<String, String>.from(uri.queryParameters);

      // YouTube 153 error is often caused by 'origin' not matching the baseUrl.
      // We force origin and widget_referrer to 'https://www.youtube-nocookie.com'
      // which is what we now use as default baseUrl in EmbedWebViewDriver.
      const String fallbackOrigin = 'https://www.youtube-nocookie.com';

      params.putIfAbsent('playsinline', () => '1');
      params['widget_referrer'] = fallbackOrigin;
      params['origin'] = fallbackOrigin;

      // DO NOT remove enablejsapi; it's required for the YoutubeEmbedPlayer
      // and any custom JS control over the player.
      // Note: We were previously stripping this, which caused state communication failure.

      final updatedSrc = uri.replace(queryParameters: params).toString();
      if (updatedSrc != currentSrc) {
        processedHtml = processedHtml.replaceFirst(currentSrc, updatedSrc);
      }
    }
  }

  return processedHtml;
}

const _errorBridgeScript = '''
<script>
  (function() {
    const report = (type, details) => {
      if (window.ErrorChannel) {
        window.ErrorChannel.postMessage(type + ': ' + (details || 'Unknown'));
      }
    };
    window.onerror = (msg, url, line, col, error) => {
      report('JS_ERROR', msg + ' at ' + url + ':' + line);
    };
    window.onunhandledrejection = (e) => {
      report('PROMISE_REJECTION', e.reason);
    };
    document.addEventListener('securitypolicyviolation', (e) => {
      report('CSP_VIOLATION', 'Blocked: ' + e.blockedURI + ', Directive: ' + e.violatedDirective);
    });
  })();
</script>
''';

const _resizeObserverScript = '''
$_errorBridgeScript
<script>
  (function() {
    const observer = new ResizeObserver(entries => {
      for (let entry of entries) {
         if (window.HeightChannel) {
           window.HeightChannel.postMessage(document.body.scrollHeight.toString());
         }
      }
    });
    observer.observe(document.body);
    
    // Initial height report
    setTimeout(() => {
      if (window.HeightChannel) {
        window.HeightChannel.postMessage(document.body.scrollHeight.toString());
      }
    }, 500);
  })();
</script>
''';

String _getCspMetaTag(EmbedType type) {
  return ''; // Temporarily unrestricted to debug rendering issues
}
