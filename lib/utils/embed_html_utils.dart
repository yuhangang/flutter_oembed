import 'package:oembed/domain/entities/embed_enums.dart';

String loadEmbedHtmlDocument(
  String embedData, {
  required EmbedType type,
  required EmbedContentType contentType,
  required double maxWidth,
}) {
  switch (type) {
    case EmbedType.x:
      return '''
  <!DOCTYPE html><html>
<style>
html, body {
   margin: 0;
  padding: 0;
  padding-bottom: 4px;
}
</style>
    <head>
    <meta name="viewport" content="width=device-width">
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
<style>
html, body {
margin: 0;
padding: 0;
}
blockquote.tiktok-embed {
margin: 0;
padding: 0;
width:${maxWidth}px;
}
</style>
  <head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width height=device-height">
</head>
<body>
$embedData
</body>
</html>
''';

    case EmbedType.facebook:
    case EmbedType.facebook_video:
    case EmbedType.facebook_post:
      final isFacebookVideo = type == EmbedType.facebook_video;
      return '''
<!DOCTYPE html><html>
<style>
html, body {
margin: 0;
padding: 0;
width:${maxWidth}px;
${!isFacebookVideo ? 'background-color: white;' : ''}
}
iframe {
width: ${maxWidth}px !important;
  }
</style>
  <head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
</head>
<body>
$embedData
</body>
</html>
''';
    case EmbedType.instagram:
      return '''
<!DOCTYPE html><html>
<style>
html, body {
margin: 0;
padding: 0;
  }

</style>
  <head>
<meta charset="utf-8">
<meta name="viewport"  content="width=device-width">
</head>
<body>

$embedData

</body>
</html>
''';

    case EmbedType.youtube:
      throw UnimplementedError();
  }
}
