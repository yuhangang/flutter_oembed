import 'package:flutter_oembed/src/models/core/embed_enums.dart';

// ---------------------------------------------------------------------------
// Public helpers — called by [EmbedProviderStrategy.buildHtmlDocument]
// overrides in each provider strategy.
// ---------------------------------------------------------------------------

/// Builds a minimal generic HTML wrapper suitable for most providers.
String buildGenericHtmlDocument(
  String embedHtml, {
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      padding-bottom: 8px; /* Breathing room to prevent clipping */
      width: 100%;
      $scrollStyles
    }
    img, video {
      width: 100% !important;
      height: auto !important;
      display: block;
      margin: 0 auto;
    }
    iframe {
      width: 100% !important;
      display: block;
      margin: 0 auto;
      border: none;
    }
  </style>
</head>
<body>
  <div id="embed-container">
    $embedHtml
  </div>
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for X (Twitter) embeds.
String buildXHtmlDocument(
  String embedHtml, {
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
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
    $embedHtml
  </div>
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for TikTok embeds.
String buildTikTokHtmlDocument(
  String embedHtml, {
  required double maxWidth,
  bool scrollable = false,
}) {
  // TODO: Fix extra padding for tiktok oembed
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="height=device-height">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      $scrollStyles
    }
    blockquote.tiktok-embed {
      margin: 0;
      padding: 0;
      max-width: ${maxWidth}px !important;
      min-width: auto !important;
      width: 100%;
    }
    .embed-container {
    width: 100vw;
    display: block;
    margin: 0;
    padding: 0;
  }
    
  </style>
</head>
<body>
  <div>
    $embedHtml
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
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for the TikTok Player v1 iframe host page.
String buildTikTokPlayerHtmlDocument(
  String iframeSrc, {
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      background: transparent;
      $scrollStyles
    }
    #player-shell {
      width: 100%;
      max-width: ${maxWidth}px;
      margin: 0 auto;
    }
    iframe {
      width: 100%;
      height: 100%;
      min-height: 100vh;
      display: block;
      border: 0;
    }
  </style>
</head>
<body>
  <div id="player-shell">
    <iframe
      id="tiktok-player"
      src="$iframeSrc"
      allow="autoplay; fullscreen"
      referrerpolicy="strict-origin-when-cross-origin"
      scrolling="no">
    </iframe>
  </div>
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for Facebook and Instagram embeds.
String buildMetaHtmlDocument(
  String embedHtml, {
  required EmbedType type,
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  final isFacebookVideo = type == EmbedType.facebook_video;
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
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
  $embedHtml
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for Instagram embeds.
String buildInstagramHtmlDocument(
  String embedHtml, {
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      $scrollStyles
    }
  </style>
</head>
<body>
  $embedHtml
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for YouTube embeds (includes security headers).
String buildYouTubeHtmlDocument(
  String embedHtml, {
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  final processedHtml = _injectYoutubeSecurityHeaders(embedHtml);
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      $scrollStyles
    }
  </style>
</head>
<body>
  $processedHtml
  $resizeObserverScript
</body>
</html>
''';
}

/// HTML wrapper for Reddit embeds.
String buildRedditHtmlDocument(
  String embedHtml, {
  required double maxWidth,
  bool scrollable = false,
}) {
  final scrollStyles = !scrollable ? 'overflow: hidden;' : '';
  return '''
<!DOCTYPE html><html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
    $embedHtml
  </div>
  $resizeObserverScript
</body>
</html>
''';
}

// ---------------------------------------------------------------------------
// Private internal helpers
// ---------------------------------------------------------------------------

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
      params.putIfAbsent('enablejsapi', () => '1');
      params['widget_referrer'] = fallbackOrigin;
      params['origin'] = fallbackOrigin;

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

const resizeObserverScript = '''
$_errorBridgeScript
<script>
  (function() {
    const reportHeight = () => {
       if (window.HeightChannel) {
         const height = Math.ceil(Math.max(
           document.body.scrollHeight, 
           document.body.offsetHeight, 
           document.documentElement.clientHeight, 
           document.documentElement.scrollHeight, 
           document.documentElement.offsetHeight
         ));
         window.HeightChannel.postMessage(height.toString());
       }
    };

    const observer = new ResizeObserver(reportHeight);
    observer.observe(document.body);
    observer.observe(document.documentElement);
    
    // Immediate report on domContentLoaded
    window.addEventListener('DOMContentLoaded', reportHeight);
    window.addEventListener('load', reportHeight);
    
    // Safety check after a small delay
    setTimeout(reportHeight, 500);
    setTimeout(reportHeight, 1500);
  })();
</script>
''';
