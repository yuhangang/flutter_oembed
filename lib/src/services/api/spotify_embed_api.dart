import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';

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
    EmbedConfig? config,
  }) {
    final params = {
      'url': url,
      'format': 'json',
    };
    if (queryParameters != null) {
      params.addAll(queryParameters);
    }

    final proxyUrl = config?.proxyUrl;
    final resolvedBaseUrl = proxyUrl != null ? '$proxyUrl/$baseUrl' : baseUrl;

    return Uri.parse(resolvedBaseUrl).replace(queryParameters: params);
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return const EmbedDataNotFoundException();
    return const EmbedApisException();
  }
}
