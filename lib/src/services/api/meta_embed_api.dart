import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/services/api/base_embed_api.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';

/// OEmbed API client for Meta platforms (Facebook + Instagram).
class MetaEmbedApi extends BaseEmbedApi {
  const MetaEmbedApi(
    this.embedType,
    this.width,
    this.appId,
    this.clientToken, {
    this.proxyUrl,
    this.endpoint,
  });

  final String? proxyUrl;
  final String? endpoint;
  final EmbedType embedType;
  final double width;
  final String appId;
  final String clientToken;

  static const String pageEndPoint = 'embed_page';
  static const String postEndPoint = 'embed_post';
  static const String videoEndPoint = 'embed_video';
  static const String instagramEndPoint = 'instagram_oembed';

  @override
  String get baseUrl => proxyUrl ?? 'https://graph.facebook.com/v22.0';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
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
        default:
          endPoint = pageEndPoint;
      }
    }

    return Uri.parse('$baseUrl/$endPoint').replace(
      queryParameters: {
        'url': url,
        if (appId.isNotEmpty && clientToken.isNotEmpty)
          'access_token': '$appId|$clientToken',
        'sdklocale': locale,
        if (embedType.isFacebook) 'maxwidth': width.toInt().toString(),
      },
    );
  }

  @override
  EmbedData ombedResponseModifier(EmbedData response) {
    return response.copyWith(
      html: response.html.replaceAll('src="//', 'src="https://'),
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    final errorCode = jsonDecode(response.body)?['error']?['code'];
    if (errorCode == 24) return EmbedDataNotFoundException();
    return EmbedApisException();
  }
}
