import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';


import 'package:oembed/data/oembed_data.dart';
import 'package:oembed/domain/embed_constant.dart';
import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:oembed/utils/embed_errors.dart';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

abstract class BaseOembedApi {
  String get baseUrl;

  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  });

  /// Called when the response is received from the server
  ///
  /// This is useful for modifying the response before it is cached
  OembedData ombedResponseModifier(OembedData response) => response;

  /// Called when start of the request
  ///
  /// return cache if available
  Future<OembedData?> getCachedResult(Uri uri) async {
    try {
      final cache =
          await DefaultCacheManager().getFileFromCache(uri.toString());
      final bytes = await cache?.file.readAsBytes();

      if (bytes != null) {
        return OembedData.fromJson(jsonDecode(utf8.decode(bytes)));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Called when the response is received from the server
  ///
  /// Saved the response to cache
  Future<void> setCachedResult(Uri uri, OembedData oembedData) async {
    try {
      await DefaultCacheManager().putFile(
        uri.toString(),
        Uint8List.fromList(jsonEncode(oembedData.toJson()).codeUnits),
        maxAge: oembedData.cacheAgeDuration ?? kDefaultEmbedHtmlCacheLifeSpan,
      );
    } catch (e) {
      return;
    }
  }

  /// Called when there is an error in Oembed response
  ///
  /// return appropriate exception based on the response
  Exception handleErrorResponse(http.Response response);

  /// Called when embed widget is initialized
  ///
  /// if cache is available return the cached data
  /// else fetch the data from the server.
  /// if the response is successful, save the response to cache
  /// else throw appropriate exception
  Future<OembedData> getOembedData(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) async {
    final uri = constructUrl(url, locale: locale, brightness: brightness);
    final cacheResult = await getCachedResult(uri);

    if (cacheResult != null) {
      return cacheResult;
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = ombedResponseModifier(
        OembedData.fromJson(json.decode(response.body)),
      );

      await setCachedResult(uri, decoded);

      return decoded;
    } else {
      throw handleErrorResponse(response);
    }
  }
}

class XEmbedApi extends BaseOembedApi {
  @override
  String get baseUrl => 'https://publish.twitter.com/oembed';

  static const _localeMap = {
    'en': 'en',
    'ms': 'msa',
    'zh': 'zh-cn',
  };

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) {
    final uri = Uri.parse(baseUrl);

    return uri.replace(
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
    if (response.statusCode == 404) {
      return EmbedDataNotFoundException();
    } else if (response.statusCode == 403) {
      return EmbedDataRestrictedAccessException();
    } else {
      return EmbedApisException();
    }
  }
}

class TikTokEmbedApi extends BaseOembedApi {
  TikTokEmbedApi();

  @override
  String get baseUrl => 'https://www.tiktok.com/oembed';

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) =>
      Uri.parse('$baseUrl?url=$url');

  @override
  Exception handleErrorResponse(http.Response response) {
    return EmbedApisException();
  }
}

class MetaEmbedApi extends BaseOembedApi {
  MetaEmbedApi(this.embedType, this.width, this.appId, this.clientToken);

  final EmbedType embedType;
  final double width;
  final String appId;
  final String clientToken;

  @override
  String get baseUrl => 'https://graph.facebook.com/v22.0';

  static const String pageEndPoint = 'oembed_page';
  static const String postEndPoint = 'oembed_post';
  static const String videoEndPoint = 'oembed_video';
  static const String instagramEndPoint = 'instagram_oembed';

  /// access token = facebookAppId|clientToken
  

  @override
  Uri constructUrl(
    String url, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
  }) {
    final Uri postUri = Uri.parse(url);
    String endPoint;

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
        endPoint = getFacebookEmbedAPIEndPoint(postUri);
    }

    final uri = Uri.parse(
      '$baseUrl/$endPoint',
    ).replace(
      queryParameters: {
        'url': url,
        'access_token': '$appId|$clientToken',
        'sdklocale': locale,
        // TODO: Applied to Instagram when iframe embed is stable on FB post
        if (embedType.isFacebook) ...{
          'maxwidth': width.toString(),
        },
      },
    );

    return uri;
  }

  /// This method is used to determine the endpoint for Meta embed api
  /// , if embed type is not explicitly provided
  String getFacebookEmbedAPIEndPoint(Uri postUri) {
    if (postUri.authority.contains('instagram')) {
      return instagramEndPoint;
    } else if (postUri.pathSegments.firstWhereOrNull(
          (element) =>
              element == 'posts' ||
              element == 'photo' ||
              element == 'photos' ||
              element == 'media',
        ) !=
        null) {
      return postEndPoint;
    } else if (postUri.pathSegments.firstWhereOrNull(
              (element) =>
                  element == 'videos' ||
                  element == 'watch' ||
                  element == 'reel',
            ) !=
            null ||
        postUri.pathSegments.contains('videos') ||
        postUri.pathSegments.contains('watch') ||
        postUri.authority.contains('fb.watch')) {
      return videoEndPoint;
    } else {
      return pageEndPoint;
    }
  }

  @override
  OembedData ombedResponseModifier(OembedData response) {
    return response.copyWith(
      html: response.html.replaceAll('src="//', 'src="https://'),
    );
  }

  @override
  Exception handleErrorResponse(http.Response response) {
    final errorCode = jsonDecode(response.body)?['error']?['code'];

    if (errorCode == 24) {
      return EmbedDataNotFoundException();
    } else {
      return EmbedApisException();
    }
  }
}
