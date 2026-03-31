import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';

/// OEmbed API client for X (formerly Twitter).
class XEmbedApi extends BaseEmbedApi {
  const XEmbedApi();

  static const _localeMap = {'en': 'en', 'ms': 'msa', 'zh': 'zh-cn'};

  @override
  String get baseUrl => 'https://publish.twitter.com/oembed';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) {
    return Uri.parse(baseUrl).replace(
      queryParameters: {
        'url': url,
        'theme': brightness == Brightness.light ? 'light' : 'dark',
        'lang': _localeMap[locale],
        'chrome': 'noscrollbar nofooter noborders transparent',
      },
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    if (response.statusCode == 404) return EmbedDataNotFoundException();
    if (response.statusCode == 403) return EmbedDataRestrictedAccessException();
    return EmbedApisException();
  }
}
