import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/models/soundcloud_embed_params.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

/// OEmbed API client for SoundCloud.
class SoundCloudEmbedApi extends BaseEmbedApi {
  const SoundCloudEmbedApi(this.width, {this.soundCloudParams});

  final double width;
  final SoundCloudEmbedParams? soundCloudParams;

  @override
  String get baseUrl => 'https://soundcloud.com/oembed';

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
      'maxwidth': width.toInt().toString(),
    };

    if (soundCloudParams != null) {
      params.addAll(soundCloudParams!.toMap());
    }

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
    return const EmbedApisException();
  }
}
