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
</body>
</html>
''';
    // Currently not in used, as current using url to load TikTok embeds
    case EmbedType.tiktok:
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

      const observer = new ResizeObserver(entries => {
        for (let entry of entries) {
           if (window.HeightChannel) {
             window.HeightChannel.postMessage(document.body.scrollHeight.toString());
           }
        }
      });
      observer.observe(document.body);
    })();
  </script>
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
</body>
</html>
''';

    case EmbedType.youtube:
    case EmbedType.spotify:
    case EmbedType.vimeo:
    case EmbedType.dailymotion:
    case EmbedType.soundcloud:
    case EmbedType.threads:
    case EmbedType.reddit:
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
    .reddit-embed-container {
      display: flex;
      justify-content: center;
      width: 100%;
    }
    blockquote.reddit-embed-bq {
      margin: 0 !important;
      width: 100% !important;
      max-width: ${maxWidth}px !important;
    }
  </style>
</head>
<body>
  <div class="reddit-embed-container">
    $embedData
  </div>
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
    })();
  </script>
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
</body>
</html>
''';
  }
}

String _getCspMetaTag(EmbedType type) {
  return ''; // Temporarily unrestricted to debug rendering issues
}
