import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oembed/src/services/api/base_oembed_api.dart';
import 'package:oembed/src/utils/embed_errors.dart';

/// OEmbed API client for Spotify.
class SpotifyEmbedApi extends BaseOembedApi {
  const SpotifyEmbedApi();

  @override
  String get baseUrl => 'https://open.spotify.com/oembed';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) {
    return Uri.parse(baseUrl).replace(queryParameters: {'url': url});
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
