import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oembed/src/services/api/base_oembed_api.dart';
import 'package:oembed/src/utils/embed_errors.dart';

/// OEmbed API client for Reddit.
class RedditEmbedApi extends BaseOembedApi {
  const RedditEmbedApi({this.width});

  final double? width;

  @override
  String get baseUrl => 'https://www.reddit.com/oembed';

  @override
  Map<String, String> get headers => {
        'User-Agent': 'flutter_oembed (https://github.com/yuhangang/flutter_oembed)',
      };

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) {
    return Uri.parse(baseUrl).replace(
      queryParameters: {
        'url': url,
        'format': 'json',
        if (width != null) 'maxwidth': width!.toInt().toString(),
        if (brightness == Brightness.dark) 'theme': 'dark',
      },
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
