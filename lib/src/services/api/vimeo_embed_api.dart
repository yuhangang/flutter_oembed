import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';

/// OEmbed API client for Vimeo.
class VimeoEmbedApi extends BaseEmbedApi {
  const VimeoEmbedApi(this.width);

  final double width;

  @override
  String get baseUrl => 'https://vimeo.com/api/oembed.json';

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
        'maxwidth': width.toInt().toString(),
      },
    );
  }

  @override
  Map<String, String> get headers => {'Referer': 'https://vimeo.com/'};

  @override
  EmbedData ombedResponseModifier(EmbedData response) {
    return response.copyWith(
      html: response.html.replaceAll('src="//', 'src="https://'),
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
