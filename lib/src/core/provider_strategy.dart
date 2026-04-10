import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_renderer.dart';
import 'package:flutter_oembed/src/models/provider_rule.dart';
import 'package:flutter_oembed/src/services/api/base_embed_api.dart';
import 'package:flutter_oembed/src/utils/embed_html_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Defines provider-specific behaviors for rendering and interaction.
///
/// This strategy decouples the core [EmbedService] and [EmbedWebViewDriver]
/// from specific provider implementations like YouTube, TikTok, etc.
abstract class EmbedProviderStrategy {
  const EmbedProviderStrategy();

  /// The User-Agent to use for this provider's WebView.
  /// If null, the default browser User-Agent will be used.
  String? get userAgent => null;

  /// Whether the provider manages its own loading-state signal (e.g. via a
  /// JavaScript channel callback). When `true`, [EmbedWebViewDriver] will
  /// wait for the provider signal before falling back to height-based
  /// detection, rather than aggressively setting an error state.
  bool get deferLoadingState => false;

  /// Custom JavaScript to run when the page starts loading.
  Future<void> onPageStarted(WebViewController controller) async {}

  /// Custom JavaScript to run when the page finishes loading.
  Future<void> onPageFinished(WebViewController controller) async {}

  /// Custom JavaScript to run when the page is being initialized (e.g. adding channels).
  Future<void> onWebViewCreated(
    WebViewController controller, {
    VoidCallback? onTwitterLoaded,
  }) async {}

  /// Pause any media (video/audio) currently playing in the WebView.
  Future<void> pauseMedia(WebViewController controller) async {
    // Default implementation: try to pause all video/audio tags
    await controller.runJavaScript('''
      document.querySelectorAll('video, audio').forEach(m => m.pause());
    ''');
  }

  /// Resolves the base URL for the WebView's HTML content.
  /// If null, no base URL will be used.
  String? resolveBaseUrl(EmbedData? data) => null;

  /// Builds the full HTML document string that will be loaded into the WebView.
  ///
  /// Override to provide provider-specific HTML wrappers, CSS, or script
  /// injection. The default implementation delegates to [buildGenericHtmlDocument].
  String buildHtmlDocument(
    String embedHtml, {
    required EmbedType type,
    required double maxWidth,
    bool scrollable = false,
  }) {
    return buildGenericHtmlDocument(
      embedHtml,
      maxWidth: maxWidth,
      scrollable: scrollable,
    );
  }

  /// Factory for creating the [BaseEmbedApi] for this provider.
  BaseEmbedApi createApi(EmbedProviderContext context);

  /// Determines how this embed should be rendered based on the provided context.
  EmbedRenderer resolveRenderer(EmbedProviderContext context,
      {EmbedConfig? config}) {
    if (context.iframeUrl != null) {
      return IframeRenderer(context.iframeUrl!);
    }
    return const OEmbedRenderer();
  }
}

/// A generic strategy that applies standard oEmbed behaviors.
class GenericEmbedProviderStrategy extends EmbedProviderStrategy {
  const GenericEmbedProviderStrategy();

  @override
  String? resolveBaseUrl(EmbedData? data) {
    if (data == null || data.providerUrl == null) return null;
    final providerUrl = data.providerUrl!;
    return providerUrl.endsWith('/')
        ? providerUrl.substring(0, providerUrl.length - 1)
        : providerUrl;
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
