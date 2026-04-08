import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

/// OEmbed API client for TikTok.
class TikTokEmbedApi extends BaseEmbedApi {
  const TikTokEmbedApi();

  @override
  String get baseUrl => 'https://www.tiktok.com/oembed';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    Map<String, String>? queryParameters,
  }) {
    final params = {'url': url};
    if (queryParameters != null) {
      params.addAll(queryParameters);
    }
    return Uri.parse(baseUrl).replace(queryParameters: params);
  }

  @override
  Exception handleErrorResponse(http.Response response) =>
      const EmbedApisException();
}
