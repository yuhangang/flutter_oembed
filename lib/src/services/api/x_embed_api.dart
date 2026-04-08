import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/models/x_embed_params.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

/// OEmbed API client for X (formerly Twitter).
class XEmbedApi extends BaseEmbedApi {
  const XEmbedApi({this.xParams});

  final XEmbedParams? xParams;

  static const _localeMap = {'en': 'en', 'ms': 'msa', 'zh': 'zh-cn'};

  @override
  String get baseUrl => 'https://publish.twitter.com/oembed';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    Map<String, String>? queryParameters,
  }) {
    final params = {
      'url': url,
      'theme': brightness == Brightness.light ? 'light' : 'dark',
      'lang': _localeMap[locale] ?? 'en',
      'chrome': 'noscrollbar nofooter noborders transparent',
    };

    if (xParams != null) {
      params.addAll(xParams!.toMap());
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
    if (response.statusCode == 403) return EmbedDataRestrictedAccessException();
    return const EmbedApisException();
  }
}
