import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_oembed/src/models/params/meta_embed_params.dart';

/// OEmbed API client for Meta platforms (Facebook + Instagram).
class MetaEmbedApi extends BaseEmbedApi {
  const MetaEmbedApi(
    this.embedType,
    this.width,
    this.appId,
    this.clientToken, {
    this.endpoint,
    this.metaParams,
    super.proxyUrl,
  });

  final String? endpoint;
  final EmbedType embedType;
  final double width;
  final String? appId;
  final String? clientToken;
  final MetaEmbedParams? metaParams;

  static const String pageEndPoint = 'embed_page';
  static const String postEndPoint = 'embed_post';
  static const String videoEndPoint = 'embed_video';
  static const String instagramEndPoint = 'instagram_oembed';

  @override
  String get baseUrl {
    if (embedType == EmbedType.threads) return 'https://graph.threads.net/v1.0';
    return 'https://graph.facebook.com/v25.0';
  }

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    Map<String, String>? queryParameters,
  }) {
    String endPoint;

    if (endpoint != null) {
      endPoint = endpoint!;
    } else {
      switch (embedType) {
        case EmbedType.facebook_post:
          endPoint = postEndPoint;
          break;
        case EmbedType.facebook_video:
          endPoint = videoEndPoint;
          break;
        case EmbedType.instagram:
          endPoint = instagramEndPoint;
          break;
        case EmbedType.threads:
          endPoint = 'oembed';
          break;
        default:
          endPoint = pageEndPoint;
      }
    }

    final params = {
      'url': url,
      if (appId != null && clientToken != null)
        'access_token': '$appId|$clientToken',
      if (metaParams?.maxwidth == null) 'maxwidth': width.toInt().toString(),
    };

    if (metaParams != null) {
      params.addAll(metaParams!.toMap());
    }

    params.putIfAbsent('sdklocale', () => locale);

    if (queryParameters != null) {
      params.addAll(queryParameters);
    }

    return Uri.parse('$baseUrl/$endPoint').replace(
      queryParameters: params,
    );
  }

  @override
  EmbedData oembedResponseModifier(EmbedData response) {
    return response.copyWith(
      html: response.html.replaceAll('src="//', 'src="https://'),
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final errorCode = body?['error']?['code'];
      if (errorCode == 24) return const EmbedDataNotFoundException();
    } catch (_) {
      // Body is not valid JSON, fall through to generic error
    }
    return const EmbedApisException();
  }
}
