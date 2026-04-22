import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'dart:convert';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/params/meta_embed_params.dart';
import 'package:flutter_oembed/src/services/api/meta_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('MetaEmbedApi', () {
    const appId = 'app123';
    const clientToken = 'token456';
    const width = 640.0;

    test('constructUrl for facebook_post', () {
      const api =
          MetaEmbedApi(EmbedType.facebook_post, width, appId, clientToken);
      final uri = api.constructUrl('https://facebook.com/post/1');

      expect(uri.path, contains('embed_post'));
      expect(
          uri.queryParameters['access_token'], equals('$appId|$clientToken'));
      expect(uri.queryParameters['maxwidth'], equals('640'));
    });

    test('constructUrl for instagram', () {
      const api = MetaEmbedApi(EmbedType.instagram, width, appId, clientToken);
      final uri = api.constructUrl('https://instagram.com/p/1');

      expect(uri.path, contains('instagram_oembed'));
    });

    test('constructUrl for threads', () {
      const api = MetaEmbedApi(EmbedType.threads, width, appId, clientToken);
      final uri = api.constructUrl('https://threads.net/t/1');

      expect(uri.host, equals('graph.threads.net'));
      expect(uri.path, contains('oembed'));
    });

    test('constructUrl with proxyUrl in config', () {
      const api =
          MetaEmbedApi(EmbedType.facebook_post, width, appId, clientToken);
      final uri = api.constructUrl(
        'https://facebook.com/post/1',
        config: const EmbedConfig(proxyUrl: 'https://myproxy.com'),
      );

      expect(uri.toString(), startsWith('https://myproxy.com'));
    });

    test('constructUrl with metaParams', () {
      const params = MetaEmbedParams(omitscript: true);
      const api = MetaEmbedApi(
          EmbedType.facebook_post, width, appId, clientToken,
          metaParams: params);
      final uri = api.constructUrl('https://facebook.com/post/1');

      expect(uri.queryParameters['omitscript'], equals('true'));
    });

    test('constructUrl ignores brightness for meta providers', () {
      const api =
          MetaEmbedApi(EmbedType.facebook_post, width, appId, clientToken);
      final lightUri = api.constructUrl(
        'https://facebook.com/post/1',
        brightness: Brightness.light,
      );
      final darkUri = api.constructUrl(
        'https://facebook.com/post/1',
        brightness: Brightness.dark,
      );

      expect(darkUri.queryParameters, equals(lightUri.queryParameters));
      expect(darkUri.queryParameters.containsKey('theme'), isFalse);
    });

    test('oembedResponseModifier fixes protocol-less src', () {
      const api =
          MetaEmbedApi(EmbedType.facebook_post, width, appId, clientToken);
      final data = const EmbedData(
          html: '<script src="//connect.facebook.net"></script>');
      final modified = api.oembedResponseModifier(data);

      expect(modified.html, contains('src="https://connect.facebook.net"'));
    });

    test('handleErrorResponse returns EmbedDataNotFoundException for code 24',
        () {
      const api =
          MetaEmbedApi(EmbedType.facebook_post, width, appId, clientToken);
      final response = http.Response(
          jsonEncode({
            'error': {'code': 24}
          }),
          400);

      expect(
          api.handleErrorResponse(response), isA<EmbedDataNotFoundException>());
    });

    test('handleErrorResponse returns EmbedApisException for other codes', () {
      const api =
          MetaEmbedApi(EmbedType.facebook_post, width, appId, clientToken);
      final response = http.Response(
          jsonEncode({
            'error': {'code': 100}
          }),
          400);

      expect(api.handleErrorResponse(response), isA<EmbedApisException>());
    });
  });
}
