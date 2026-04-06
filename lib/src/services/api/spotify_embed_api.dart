import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';

/// OEmbed API client for Spotify.
class SpotifyEmbedApi extends BaseEmbedApi {
  const SpotifyEmbedApi();

  @override
  String get baseUrl => 'https://open.spotify.com/oembed';

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
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
