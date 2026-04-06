import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/provider_strategy.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/meta_embed_params.dart';
import 'package:flutter_embed/src/models/soundcloud_embed_params.dart';
import 'package:flutter_embed/src/models/vimeo_embed_params.dart';
import 'package:flutter_embed/src/models/x_embed_params.dart';
import 'package:flutter_embed/src/services/embed_apis.dart';
import 'package:flutter_embed/src/utils/embed_webview_controller_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeProviderStrategy extends GenericEmbedProviderStrategy {
  const YouTubeProviderStrategy();

  @override
  String get userAgent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/122.0.0.0 Safari/537.36';

  @override
  String? resolveBaseUrl(EmbedData? data) => 'https://www.youtube-nocookie.com';

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return GenericEmbedApi(
      'https://www.youtube.com/oembed',
      width: context.width,
    );
  }

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseVideos();
  }
}

class TikTokProviderStrategy extends GenericEmbedProviderStrategy {
  const TikTokProviderStrategy();

  @override
  String get userAgent =>
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.4 Mobile/15E148 Safari/604.1';

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return const TikTokEmbedApi();
  }

  @override
  Future<void> onPageFinished(WebViewController controller) async {
    // TikTok handles its own pausing via IntersectionObserver in their script,
    // but we can try to mute it if it's a photo post.
    await controller.runJavaScript('''
      document.querySelectorAll('video, audio').forEach(m => {
        m.muted = true;
        m.pause();
      });
    ''');
  }

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    // TikTok handles its own pausing via IntersectionObserver in their script,
    // but we can try to mute it if it's a photo post.
    await controller.muteAudioWidget();
  }
}

class XProviderStrategy extends GenericEmbedProviderStrategy {
  const XProviderStrategy();

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
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return VimeoEmbedApi(
      context.width,
      vimeoParams: context.embedParams as VimeoEmbedParams?,
    );
  }

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseVideos();
  }
}

class SoundCloudProviderStrategy extends GenericEmbedProviderStrategy {
  const SoundCloudProviderStrategy();

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return SoundCloudEmbedApi(
      context.width,
      soundCloudParams: context.embedParams as SoundCloudEmbedParams?,
    );
  }

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseVideos();
  }
}

class SpotifyProviderStrategy extends GenericEmbedProviderStrategy {
  const SpotifyProviderStrategy();

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return const SpotifyEmbedApi();
  }

  @override
  Future<void> pauseMedia(WebViewController controller) async {
    await controller.pauseVideos();
  }
}

class RedditProviderStrategy extends GenericEmbedProviderStrategy {
  const RedditProviderStrategy();

  @override
  BaseEmbedApi createApi(EmbedProviderContext context) {
    return RedditEmbedApi(width: context.width);
  }
}
