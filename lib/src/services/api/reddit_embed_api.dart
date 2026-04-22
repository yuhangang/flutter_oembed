import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

/// OEmbed API client for Reddit.
class RedditEmbedApi extends BaseEmbedApi {
  const RedditEmbedApi({this.width});

  final double? width;

  @override
  String get baseUrl => 'https://www.reddit.com/oembed';

  @override
  Map<String, String> get headers => {
        'User-Agent':
            'flutter_embed (https://github.com/yuhangang/flutter_embed)',
      };

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    Map<String, String>? queryParameters,
    EmbedConfig? config,
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

    final proxyUrl = config?.proxyUrl;
    final resolvedBaseUrl = proxyUrl != null ? '$proxyUrl/$baseUrl' : baseUrl;

    return Uri.parse(resolvedBaseUrl).replace(
      queryParameters: params,
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return const EmbedDataNotFoundException();
    return const EmbedApisException();
  }
}
