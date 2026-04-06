import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';

/// OEmbed API client for Reddit.
class RedditEmbedApi extends BaseEmbedApi {
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
    Map<String, String>? queryParameters,
  }) {
    final params = {
      'url': url,
      'format': 'json',
      if (width != null) 'maxwidth': width!.toInt().toString(),
      if (brightness == Brightness.dark) 'theme': 'dark',
    };

    if (queryParameters != null) {
      params.addAll(queryParameters);
    }

    return Uri.parse(baseUrl).replace(
      queryParameters: params,
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
