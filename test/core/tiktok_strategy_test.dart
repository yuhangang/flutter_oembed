import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:flutter_oembed/src/core/provider_strategies.dart';
import 'package:flutter_oembed/src/models/core/embed_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TikTokProviderStrategy', () {
    const strategy = TikTokProviderStrategy();

    test('resolveRenderer returns OEmbedRenderer by default', () {
      final context = EmbedProviderContext(
        url: 'https://www.tiktok.com/@user/video/123',
        resolvedEndpoint: 'https://www.tiktok.com/oembed',
        width: 320,
        locale: 'en',
        brightness: ThemeMode.light.index == 0
            ? Brightness.light
            : Brightness.dark, // Mock brightness
        facebookAppId: '',
        facebookClientToken: '',
        strategy: strategy,
        providerName: 'TikTok',
      );

      final renderer = strategy.resolveRenderer(context);
      expect(renderer, isA<OEmbedRenderer>());
    });

    test(
        'resolveRenderer returns NativeWidgetRenderer when useV1Player is true',
        () {
      final context = const EmbedProviderContext(
        url: 'https://www.tiktok.com/@user/video/123',
        resolvedEndpoint: 'https://www.tiktok.com/oembed',
        width: 320,
        locale: 'en',
        brightness: Brightness.light,
        facebookAppId: '',
        facebookClientToken: '',
        strategy: strategy,
        providerName: 'TikTok',
        embedParams: TikTokEmbedParams(useV1Player: true),
      );

      final renderer = strategy.resolveRenderer(context);
      expect(renderer, isA<NativeWidgetRenderer>());
    });

    test(
        'resolveRenderer returns NativeWidgetRenderer when embedType is tiktok_v1',
        () {
      final context = const EmbedProviderContext(
        url: 'https://www.tiktok.com/@user/video/123',
        resolvedEndpoint: 'https://www.tiktok.com/oembed',
        width: 320,
        locale: 'en',
        brightness: Brightness.light,
        facebookAppId: '',
        facebookClientToken: '',
        strategy: strategy,
        providerName: 'TikTok',
        embedType: EmbedType.tiktok_v1,
      );

      final renderer = strategy.resolveRenderer(context);
      expect(renderer, isA<NativeWidgetRenderer>());
    });

    test('resolveRenderer returns IframeRenderer when iframeUrl is provided',
        () {
      final context = const EmbedProviderContext(
        url: 'https://www.tiktok.com/@user/video/123',
        resolvedEndpoint: 'https://www.tiktok.com/oembed',
        width: 320,
        locale: 'en',
        brightness: Brightness.light,
        facebookAppId: '',
        facebookClientToken: '',
        strategy: strategy,
        providerName: 'TikTok',
        iframeUrl: 'https://www.tiktok.com/embed/v3/123',
      );

      final renderer = strategy.resolveRenderer(context);
      expect(renderer, isA<IframeRenderer>());
      expect((renderer as IframeRenderer).iframeUrl,
          equals('https://www.tiktok.com/embed/v3/123'));
    });
  });
}
