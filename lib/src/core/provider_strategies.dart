import 'dart:ui';

import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_renderer.dart';
import 'package:flutter_oembed/src/models/meta_embed_params.dart';
import 'package:flutter_oembed/src/models/soundcloud_embed_params.dart';
import 'package:flutter_oembed/src/models/tiktok_embed_params.dart';
import 'package:flutter_oembed/src/models/vimeo_embed_params.dart';
import 'package:flutter_oembed/src/models/x_embed_params.dart';
import 'package:flutter_oembed/src/models/youtube_embed_params.dart';
import 'package:flutter_oembed/src/services/embed_apis.dart';
import 'package:flutter_oembed/src/utils/embed_html_utils.dart';
import 'package:flutter_oembed/src/utils/embed_webview_controller_utils.dart';
import 'package:flutter_oembed/src/widgets/tiktok_embed_player.dart';
import 'package:flutter_oembed/src/widgets/youtube_embed_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeProviderStrategy extends GenericEmbedProviderStrategy {
  const YouTubeProviderStrategy();

  @override
  EmbedMediaStrategy? get mediaStrategy => const YouTubeMediaStrategy();

  @override
  String get userAgent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/122.0.0.0 Safari/537.36';

  @override
  String? resolveBaseUrl(EmbedData? data) => 'https://www.youtube-nocookie.com';

  @override
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    return buildYouTubeHtmlDocument(
      embedHtml,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return GenericEmbedApi(
      'https://www.youtube.com/oembed',
      width: context.width,
    );
  }

  @override
  EmbedRenderer resolveRenderer(EmbedProviderContext context,
      {EmbedConfig? config}) {
    if (context.iframeUrl != null) {
      return IframeRenderer(context.iframeUrl!);
    }

    // Otherwise fallback to YouTube native player
    return NativeWidgetRenderer(
        (widgetContext, maxWidth, controller, embedConstraints) {
      return YoutubeEmbedPlayer(
        videoIdOrUrl: context.url,
        maxWidth: maxWidth,
        embedConstraints: embedConstraints,
        controls:
            (context.embedParams as YoutubeEmbedParams?)?.controls ?? true,
        autoplay:
            (context.embedParams as YoutubeEmbedParams?)?.autoplay ?? false,
        loop: (context.embedParams as YoutubeEmbedParams?)?.loop ?? false,
        rel: (context.embedParams as YoutubeEmbedParams?)?.rel ?? false,
        theme: (context.embedParams as YoutubeEmbedParams?)?.theme,
        color: (context.embedParams as YoutubeEmbedParams?)?.color,
        controller: controller,
      );
    });
  }
}

class TikTokProviderStrategy extends GenericEmbedProviderStrategy {
  const TikTokProviderStrategy();

  @override
  EmbedMediaStrategy? get mediaStrategy => const TikTokMediaStrategy();

  @override
  String get userAgent =>
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.4 Mobile/15E148 Safari/604.1';

  @override
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    if (type == EmbedType.tiktok_v1) {
      return buildTikTokPlayerHtmlDocument(
        embedHtml,
        maxWidth: maxWidth,
        scrollable: scrollable,
      );
    }

    return buildTikTokHtmlDocument(
      embedHtml,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return TikTokEmbedApi(
      tiktokParams: context.embedParams as TikTokEmbedParams?,
    );
  }

  @override
  Future<void> onPageFinished(WebViewController controller) async {
    // TikTok handles its own pausing via IntersectionObserver in their script,
    // but we can try to mute it if it's a photo post.
    await controller.muteMediaElements();
    await controller.pauseMediaElements();
  }

  @override
  EmbedRenderer resolveRenderer(EmbedProviderContext context,
      {EmbedConfig? config}) {
    final params = context.embedParams as TikTokEmbedParams?;
    final isV1Type = context.embedType == EmbedType.tiktok_v1;

    if (isV1Type || params?.useV1Player == true) {
      return NativeWidgetRenderer(
          (widgetContext, maxWidth, controller, embedConstraints) {
        return TikTokEmbedPlayer(
          videoIdOrUrl: context.url,
          maxWidth: maxWidth,
          embedConstraints: embedConstraints,
          embedParams: params,
          controller: controller,
        );
      });
    }

    return super.resolveRenderer(context, config: config);
  }
}

class XProviderStrategy extends GenericEmbedProviderStrategy {
  const XProviderStrategy();

  @override
  bool get deferLoadingState => true;

  @override
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    return buildXHtmlDocument(
      embedHtml,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return XEmbedApi(xParams: context.embedParams as XEmbedParams?);
  }

  @override
  Future<void> onWebViewCreated(
    WebViewController controller, {
    VoidCallback? onTwitterLoaded,
  }) async {
    await controller.addJavaScriptChannel(
      'OnTwitterLoaded',
      onMessageReceived: (_) => onTwitterLoaded?.call(),
    );
  }

  @override
  Future<void> onPageFinished(WebViewController controller) async {
    await controller.runJavaScript('''
      twttr.events.bind('loaded', function(event) {
        if (window.OnTwitterLoaded) {
          OnTwitterLoaded.postMessage("loaded");
        }
      });
    ''');
  }
}

class MetaProviderStrategy extends GenericEmbedProviderStrategy {
  final EmbedType type;
  const MetaProviderStrategy(this.type);

  @override
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    if (type == EmbedType.instagram) {
      return buildInstagramHtmlDocument(
        embedHtml,
        maxWidth: maxWidth,
        scrollable: scrollable,
      );
    }
    return buildMetaHtmlDocument(
      embedHtml,
      type: type,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return MetaEmbedApi(
      type,
      context.width,
      context.facebookAppId,
      context.facebookClientToken,
      proxyUrl: context.proxyUrl,
      metaParams: context.embedParams as MetaEmbedParams?,
    );
  }
}

class VimeoProviderStrategy extends GenericEmbedProviderStrategy {
  const VimeoProviderStrategy();

  @override
  EmbedMediaStrategy? get mediaStrategy => const VimeoMediaStrategy();

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return VimeoEmbedApi(
      context.width,
      vimeoParams: context.embedParams as VimeoEmbedParams?,
    );
  }
}

class SoundCloudProviderStrategy extends GenericEmbedProviderStrategy {
  const SoundCloudProviderStrategy();

  @override
  EmbedMediaStrategy? get mediaStrategy => const SoundCloudMediaStrategy();

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return SoundCloudEmbedApi(
      context.width,
      soundCloudParams: context.embedParams as SoundCloudEmbedParams?,
    );
  }
}

class SpotifyProviderStrategy extends GenericEmbedProviderStrategy {
  const SpotifyProviderStrategy();

  @override
  EmbedMediaStrategy? get mediaStrategy => const SpotifyMediaStrategy();

  @override
  String get userAgent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/122.0.0.0 Safari/537.36';

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return const SpotifyEmbedApi();
  }
}

class DailymotionProviderStrategy extends GenericEmbedProviderStrategy {
  const DailymotionProviderStrategy();

  @override
  EmbedMediaStrategy? get mediaStrategy => const DailymotionMediaStrategy();

  @override
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    var modifiedHtml = embedHtml.replaceFirst(
      'src="https://geo.dailymotion.com/player.html?',
      'src="https://geo.dailymotion.com/player.html?api=postMessage&',
    );

    if (modifiedHtml == embedHtml &&
        modifiedHtml
            .contains('src="https://www.dailymotion.com/embed/video/')) {
      final match = RegExp(
              r'src="(https:\/\/www\.dailymotion\.com\/embed\/video\/[^"]+)"')
          .firstMatch(modifiedHtml);
      if (match != null) {
        final srcUrl = match.group(1)!;
        final newSrc = srcUrl.contains('?')
            ? '$srcUrl&api=postMessage'
            : '$srcUrl?api=postMessage';
        modifiedHtml = modifiedHtml.replaceFirst(srcUrl, newSrc);
      }
    }

    return super.buildHtmlDocument(
      modifiedHtml,
      type: type,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return GenericEmbedApi(
      context.resolvedEndpoint,
      proxyUrl: context.proxyUrl,
      width: context.width,
    );
  }
}

class RedditProviderStrategy extends GenericEmbedProviderStrategy {
  const RedditProviderStrategy();

  @override
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    return buildRedditHtmlDocument(
      embedHtml,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return RedditEmbedApi(width: context.width);
  }
}

class YouTubeMediaStrategy extends EmbedMediaStrategy {
  const YouTubeMediaStrategy();

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _youTubeIframeSrcFragments,
      messageJson: _youTubePauseMessage,
    );
  }

  @override
  Future<void> resumeMedia(WebViewController controller) async {
    await controller.resumeMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _youTubeIframeSrcFragments,
      messageJson: _youTubePlayMessage,
    );
  }

  @override
  Future<void> muteMedia(WebViewController controller) async {
    await controller.muteMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _youTubeIframeSrcFragments,
      messageJson: _youTubeMuteMessage,
    );
  }

  @override
  Future<void> unmuteMedia(WebViewController controller) async {
    await controller.unmuteMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _youTubeIframeSrcFragments,
      messageJson: _youTubeUnmuteMessage,
    );
  }
}

class TikTokMediaStrategy extends EmbedMediaStrategy {
  const TikTokMediaStrategy();

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseMediaElements();
    await controller.postJavaScriptMessageToIframes(
      srcFragments: _tikTokPlayerIframeSrcFragments,
      messageExpression: _buildTikTokPlayerCommandExpression(type: 'pause'),
    );
  }

  @override
  Future<void> resumeMedia(WebViewController controller) async {
    await controller.resumeMediaElements();
    await controller.postJavaScriptMessageToIframes(
      srcFragments: _tikTokPlayerIframeSrcFragments,
      messageExpression: _buildTikTokPlayerCommandExpression(type: 'play'),
    );
  }

  @override
  Future<void> muteMedia(WebViewController controller) async {
    await controller.muteMediaElements();
    await controller.postJavaScriptMessageToIframes(
      srcFragments: _tikTokPlayerIframeSrcFragments,
      messageExpression: _buildTikTokPlayerCommandExpression(type: 'mute'),
    );
  }

  @override
  Future<void> unmuteMedia(WebViewController controller) async {
    await controller.unmuteMediaElements();
    await controller.postJavaScriptMessageToIframes(
      srcFragments: _tikTokPlayerIframeSrcFragments,
      messageExpression: _buildTikTokPlayerCommandExpression(type: 'unMute'),
    );
  }

  @override
  Future<void> seekMediaTo(
    WebViewController controller,
    Duration position,
  ) async {
    await controller.seekMediaElementsTo(position.inMilliseconds / 1000);
    await controller.postJavaScriptMessageToIframes(
      srcFragments: _tikTokPlayerIframeSrcFragments,
      messageExpression: _buildTikTokPlayerCommandExpression(
        type: 'seekTo',
        value: position.inSeconds,
      ),
    );
  }
}

class VimeoMediaStrategy extends EmbedMediaStrategy {
  const VimeoMediaStrategy();

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _vimeoIframeSrcFragments,
      messageJson: _vimeoPauseMessage,
    );
  }

  @override
  Future<void> resumeMedia(WebViewController controller) async {
    await controller.resumeMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _vimeoIframeSrcFragments,
      messageJson: _vimeoPlayMessage,
    );
  }

  @override
  Future<void> muteMedia(WebViewController controller) async {
    await controller.muteMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _vimeoIframeSrcFragments,
      messageJson: _vimeoMuteMessage,
    );
  }

  @override
  Future<void> unmuteMedia(WebViewController controller) async {
    await controller.unmuteMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _vimeoIframeSrcFragments,
      messageJson: _vimeoUnmuteMessage,
    );
  }
}

class SoundCloudMediaStrategy extends EmbedMediaStrategy {
  const SoundCloudMediaStrategy();

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _soundCloudIframeSrcFragments,
      messageJson: _soundCloudPauseMessage,
    );
  }

  @override
  Future<void> resumeMedia(WebViewController controller) async {
    await controller.resumeMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _soundCloudIframeSrcFragments,
      messageJson: _soundCloudPlayMessage,
    );
  }
}

class SpotifyMediaStrategy extends EmbedMediaStrategy {
  const SpotifyMediaStrategy();

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _spotifyIframeSrcFragments,
      messageJson: _spotifyPauseMessage,
    );
  }

  @override
  Future<void> resumeMedia(WebViewController controller) async {
    await controller.resumeMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _spotifyIframeSrcFragments,
      messageJson: _spotifyPlayMessage,
    );
  }
}

class DailymotionMediaStrategy extends EmbedMediaStrategy {
  const DailymotionMediaStrategy();

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _dailymotionIframeSrcFragments,
      messageJson: _dailymotionPauseMessage,
    );
  }

  @override
  Future<void> resumeMedia(WebViewController controller) async {
    await controller.resumeMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _dailymotionIframeSrcFragments,
      messageJson: _dailymotionPlayMessage,
    );
  }

  @override
  Future<void> muteMedia(WebViewController controller) async {
    await controller.muteMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _dailymotionIframeSrcFragments,
      messageJson: _dailymotionMuteMessage,
    );
  }

  @override
  Future<void> unmuteMedia(WebViewController controller) async {
    await controller.unmuteMediaElements();
    await controller.postJsonStringMessageToIframes(
      srcFragments: _dailymotionIframeSrcFragments,
      messageJson: _dailymotionUnmuteMessage,
    );
  }
}

const _youTubeIframeSrcFragments = [
  'youtube.com',
  'youtube-nocookie.com',
  'youtu.be',
];
const _vimeoIframeSrcFragments = ['vimeo.com'];
const _soundCloudIframeSrcFragments = ['soundcloud.com'];
const _spotifyIframeSrcFragments = ['spotify.com'];
const _tikTokPlayerIframeSrcFragments = ['tiktok.com/player/'];
const _dailymotionIframeSrcFragments = ['dailymotion.com'];

const _youTubePauseMessage =
    '{"event":"command","func":"pauseVideo","args":""}';
const _youTubePlayMessage = '{"event":"command","func":"playVideo","args":""}';
const _youTubeMuteMessage = '{"event":"command","func":"mute","args":""}';
const _youTubeUnmuteMessage = '{"event":"command","func":"unMute","args":""}';

const _vimeoPauseMessage = '{"method":"pause"}';
const _vimeoPlayMessage = '{"method":"play"}';
const _vimeoMuteMessage = '{"method":"setVolume","value":0}';
const _vimeoUnmuteMessage = '{"method":"setVolume","value":1}';

const _soundCloudPauseMessage = '{"method":"pause"}';
const _soundCloudPlayMessage = '{"method":"play"}';

const _spotifyPauseMessage = '{"command":"pause"}';
const _spotifyPlayMessage = '{"command":"play"}';

const _dailymotionPauseMessage = '{"command":"pause","parameters":[]}';
const _dailymotionPlayMessage = '{"command":"play","parameters":[]}';
const _dailymotionMuteMessage = '{"command":"muted","parameters":[true]}';
const _dailymotionUnmuteMessage = '{"command":"muted","parameters":[false]}';

String _buildTikTokPlayerCommandExpression({
  required String type,
  Object? value,
}) {
  final encodedValue = switch (value) {
    null => '""',
    int number => '$number',
    double number => '$number',
    bool flag => '$flag',
    String text => '"${text.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"',
    _ => '"${value.toString().replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"',
  };

  return '{"type":"$type","value":$encodedValue,"x-tiktok-player":true}';
}
