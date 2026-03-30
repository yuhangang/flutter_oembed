import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oembed/src/services/api/base_oembed_api.dart';
import 'package:oembed/src/utils/embed_errors.dart';

/// OEmbed API client for TikTok.
class TikTokEmbedApi extends BaseOembedApi {
  const TikTokEmbedApi();

  @override
  String get baseUrl => 'https://www.tiktok.com/oembed';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) => Uri.parse('$baseUrl?url=$url');

  @override
  Exception handleErrorResponse(http.Response response) => EmbedApisException();
}
