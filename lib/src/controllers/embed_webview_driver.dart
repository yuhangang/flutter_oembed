import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/controllers/embed_navigation_handler.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/utils/embed_html_utils.dart';
import 'package:flutter_embed/src/utils/embed_webview_controller_utils.dart';
import 'package:flutter_embed/src/logging/embed_logger.dart';

/// Internal driver that manages the low-level [WebViewController] interactions.
///
/// This class decouples the WebView lifecycle and platform-specific scripts
/// from the high-level [EmbedController] state.
class EmbedWebViewDriver {
  final EmbedController controller;
  final WebViewController webViewController;
  late final EmbedNavigationHandler _navigationHandler;
  bool _isDisposed = false;

  EmbedLogger get _logger =>
      controller.config?.logger ?? const EmbedLogger.disabled();

  EmbedWebViewDriver({
    required this.controller,
    WebViewController? webViewController,
  }) : webViewController = webViewController ?? generateWebViewController() {
    _navigationHandler = EmbedNavigationHandler(
      param: controller.param,
      config: controller.config,
      delegate: controller.delegate,
    );
  }

  void dispose() {
    _isDisposed = true;
    webViewController.loadRequest(Uri.parse('about:blank'));
    webViewController.setNavigationDelegate(NavigationDelegate());
  }

  /// Initialises and loads the WebView.
  Future<void> initEmbedWebview({
    required Color backgroundColor,
    required EmbedData? embedData,
    required String? embedUrl,
    required double maxWidth,
    bool scrollable = false,
    bool forceReload = false,
  }) async {
    if (!forceReload &&
        controller.loadingState == EmbedLoadingState.loaded &&
        (controller.height != null ||
            controller.param.embedType == EmbedType.tiktok)) {
      return;
    }

    _logger.debug('Initializing WebView', data: {'url': controller.param.url});
    await _initWebViewController(
      backgroundColor: backgroundColor,
      embedData: embedData,
      scrollable: scrollable,
    );

    controller.startLoadTimeout();

    await _loadEmbedWebview(
      embedData,
      maxWidth,
      embedUrl,
      scrollable,
    );
  }

  Future<void> _initWebViewController({
    required Color backgroundColor,
    required EmbedData? embedData,
    bool scrollable = false,
  }) async {
    final resolvedData = embedData ?? controller.preloadedData;
    _navigationHandler.oembedData = resolvedData;

    webViewController.setBackgroundColor(backgroundColor);
    webViewController.enableZoom(scrollable);
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (controller.param.embedType == EmbedType.youtube) {
      // Desktop Chrome user agent is more robust for bypassing YouTube's
      // embedding restrictions (Error 153) in mobile webviews.
      webViewController.setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/122.0.0.0 Safari/537.36',
      );
    } else if (controller.param.embedType.isTikTok) {
      webViewController.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/17.4 Mobile/15E148 Safari/604.1',
      );
    }

    if (controller.param.embedType == EmbedType.x) {
      await webViewController.addJavaScriptChannel(
        'OnTwitterLoaded',
        onMessageReceived: (_) async => _handleEmbedPageFinished(),
      );
    }

    await webViewController.addJavaScriptChannel(
      'HeightChannel',
      onMessageReceived: (JavaScriptMessage message) {
        final double? newHeight = double.tryParse(message.message);
        if (newHeight != null &&
            newHeight > 0 &&
            controller.loadingState == EmbedLoadingState.loaded) {
          controller.setHeight(newHeight);
        }
      },
    );

    final baseUrl = embedData?.providerUrl;

    await webViewController.setNavigationDelegate(
      _navigationHandler.buildDelegate(
        baseUrl: baseUrl,
        loadingStateGetter: () => controller.loadingState,
        onPageFinished: () async {
          if (controller.param.embedType == EmbedType.x) {
            await webViewController.runJavaScript('''
              twttr.events.bind('loaded', function(event) {
                OnTwitterLoaded.postMessage("loaded");
              });
            ''');
          } else if (controller.param.embedType.isTikTok) {
            if (controller.param.isTikTokPhoto) {
              await webViewController.muteAudioWidget();
            }
            _handleEmbedPageFinished();
          } else {
            await _handleEmbedPageFinished();
          }
        },
      ),
    );
  }

  Future<void> _loadEmbedWebview(
    EmbedData? embedData,
    double maxWidth,
    String? embedUrl,
    bool scrollable,
  ) async {
    final resolvedData = embedData ?? controller.preloadedData;
    if (resolvedData != null) {
      if (resolvedData.html.isNotEmpty) {
        await webViewController.loadHtmlString(
          loadEmbedHtmlDocument(
            resolvedData.html,
            type: controller.param.embedType,
            maxWidth: maxWidth,
            scrollable: scrollable,
          ),
          baseUrl: (controller.param.embedType.isFacebook ||
                  controller.param.embedType.isTikTok ||
                  controller.param.embedType == EmbedType.instagram ||
                  controller.param.embedType == EmbedType.youtube ||
                  controller.param.embedType == EmbedType.reddit)
              ? (controller.param.embedType == EmbedType.youtube
                  ? 'https://www.youtube-nocookie.com'
                  : (resolvedData.providerUrl?.endsWith('/') ?? false
                      ? resolvedData.providerUrl!
                          .substring(0, resolvedData.providerUrl!.length - 1)
                      : resolvedData.providerUrl))
              : null,
        );
      } else if (resolvedData.url != null && resolvedData.url!.isNotEmpty) {
        await webViewController.loadRequest(Uri.parse(resolvedData.url!));
      }
    } else if (embedUrl != null) {
      await webViewController.loadRequest(
        Uri.parse(embedUrl),
        headers: <String, String>{
          if (controller.param.embedType == EmbedType.youtube)
            'Referer': controller.param.url,
        },
      );
    }
  }

  Future<void> _handleEmbedPageFinished() async {
    // Small delay to allow initial rendering to start
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed) return;

    if (controller.loadingState != EmbedLoadingState.loaded) {
      // Initial height check
      await updateEmbedPostHeight();
      if (_isDisposed) return;

      controller.setLoadingState(EmbedLoadingState.loaded);

      // Final short delay to catch any immediate post-load shifts
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isDisposed) return;

      await updateEmbedPostHeight();
    }
  }

  Future<void> updateEmbedPostHeight() async {
    try {
      final double? newHeight =
          await webViewController.getEmbedDocumentHeight();
      if (_isDisposed) return;
      if (newHeight != null && controller.height != newHeight) {
        _logger.debug(
          'Updated embed height',
          data: {
            'url': controller.param.url,
            'height': newHeight,
          },
        );
        controller.setHeight(newHeight);
      }
    } catch (error, stackTrace) {
      _logger.debug(
        'Failed to read embed height',
        data: {'url': controller.param.url},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> pauseMedias() async {
    if (controller.param.isTikTokPhoto) {
      await webViewController.muteAudioWidget();
    } else {
      await webViewController.pauseVideos();
    }
  }

  Future<void> refresh() async {
    _logger.debug('Refreshing embed', data: {'url': controller.param.url});
    await webViewController.reload();
    controller.startLoadTimeout();
  }
}
