import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:oembed/src/models/oembed_config.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/core/oembed_delegate.dart';
import 'package:oembed/src/models/oembed_data.dart';
import 'package:oembed/src/utils/embed_html_utils.dart';
import 'package:oembed/src/utils/embed_webview_controller_utils.dart';
import 'package:oembed/src/controllers/embed_navigation_handler.dart';
import 'package:oembed/src/logging/oembed_logger.dart';

class EmbedController extends ChangeNotifier {
  final SocialEmbedParam param;
  final OembedDelegate? delegate;
  final OembedConfig? config;
  final OembedData? preloadedData;

  EmbedLoadingState loadingState = EmbedLoadingState.loading;
  bool didRetry = false;
  double? height;
  bool isVisible = true;
  bool _isDisposed = false;
  Timer? _timeoutTimer;
  late final EmbedNavigationHandler _navigationHandler;
  OembedLogger get _logger => config?.logger ?? const OembedLogger.disabled();

  late final WebViewController webViewController;

  EmbedController({
    required this.param,
    this.delegate,
    this.config,
    this.preloadedData,
  }) {
    webViewController = generateWebViewController();
    _navigationHandler = EmbedNavigationHandler(
      param: param,
      config: config,
      delegate: delegate,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    webViewController.loadRequest(Uri.parse('about:blank'));
    webViewController.setNavigationDelegate(NavigationDelegate());
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State mutations
  // ---------------------------------------------------------------------------

  void setHeight(double newHeight) {
    if (_isDisposed) return;
    if (height != newHeight) {
      height = newHeight;
      notifyListeners();
    }
  }

  void updateVisibility(
    bool visible, {
    required void Function(bool) onVisibilityChange,
  }) {
    if (_isDisposed) return;
    if (isVisible != visible) {
      isVisible = visible;
      _navigationHandler.isVisible = visible;
      notifyListeners();
      onVisibilityChange(visible);
    }
  }

  void setLoadingState(EmbedLoadingState state) {
    if (_isDisposed) return;
    if (loadingState != state) {
      loadingState = state;
      notifyListeners();
    }
  }

  void setDidRetry() {
    if (_isDisposed) return;
    if (!didRetry) {
      didRetry = true;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // WebView initialisation — now takes resolved colors instead of BuildContext
  // ---------------------------------------------------------------------------

  /// Initialises and loads the WebView.
  ///
  /// [backgroundColor] is resolved from the theme before calling this method,
  /// so we never hold a [BuildContext] across an async boundary.
  Future<void> initEmbedWebview({
    required Color backgroundColor,
    required OembedData? embedData,
    required String? embedUrl,
    required double maxWidth,
    bool scrollable = false,
  }) async {
    if (loadingState == EmbedLoadingState.loaded &&
        (height != null || param.embedType == EmbedType.tiktok)) {
      return;
    }

    _logger.debug('Initializing WebView for ${param.url}');
    await _initWebViewController(
      backgroundColor: backgroundColor,
      embedData: embedData ?? preloadedData,
      scrollable: scrollable,
    );
    _setLoadEmbedPostTimeoutFunction();
    await _loadEmbedWebview(
      embedData ?? preloadedData,
      maxWidth,
      embedUrl,
      scrollable,
    );
  }

  Future<void> _initWebViewController({
    required Color backgroundColor,
    required OembedData? embedData,
    bool scrollable = false,
  }) async {
    final resolvedData = embedData ?? preloadedData;
    _navigationHandler.oembedData = resolvedData;

    webViewController.setBackgroundColor(backgroundColor);
    webViewController.enableZoom(scrollable);
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (param.embedType == EmbedType.tiktok) {
      webViewController.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_8 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/14.1.2 Mobile/15E148 Safari/604.1',
      );
    }

    if (param.embedType == EmbedType.x) {
      await webViewController.addJavaScriptChannel(
        'OnTwitterLoaded',
        onMessageReceived: (_) async => _handleOembedPageFinished(),
      );
    }

    final baseUrl = embedData?.providerUrl;

    await webViewController.setNavigationDelegate(
      _navigationHandler.buildDelegate(
        baseUrl: baseUrl,
        loadingStateGetter: () => loadingState,
        onPageFinished: () async {
          if (param.embedType == EmbedType.x) {
            await webViewController.runJavaScript('''
              twttr.events.bind('loaded', function(event) {
                OnTwitterLoaded.postMessage("loaded");
              });
            ''');
          } else if (param.embedType == EmbedType.tiktok) {
            if (param.isTikTokPhoto) {
              await webViewController.muteAudioWidget();
            }
            _handleOembedPageFinished();
          } else {
            await _handleOembedPageFinished();
          }
        },
      ),
    );
  }

  Future<void> _loadEmbedWebview(
    OembedData? embedData,
    double maxWidth,
    String? embedUrl,
    bool scrollable,
  ) async {
    if (embedData != null) {
      await webViewController.loadHtmlString(
        loadEmbedHtmlDocument(
          embedData.html,
          type: param.embedType,
          maxWidth: maxWidth,
          scrollable: scrollable,
        ),
        baseUrl:
            (param.embedType.isFacebook ||
                    param.embedType.isTikTok ||
                    param.embedType == EmbedType.instagram ||
                    param.embedType == EmbedType.youtube)
                ? embedData.providerUrl
                : null,
      );
    } else if (embedUrl != null) {
      await webViewController.loadRequest(Uri.parse(embedUrl));
    }
  }

  Future<void> _handleOembedPageFinished() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_isDisposed) return;

    if (loadingState != EmbedLoadingState.loaded) {
      await updateEmbedPostHeight();
      if (_isDisposed) return;

      await Future.delayed(const Duration(milliseconds: 100));
      if (_isDisposed) return;

      setLoadingState(EmbedLoadingState.loaded);

      await Future.delayed(
        param.embedType.isFacebook
            ? const Duration(milliseconds: 3000)
            : const Duration(milliseconds: 1000),
      );
      if (_isDisposed) return;

      await updateEmbedPostHeight();
    }
  }

  // ---------------------------------------------------------------------------
  // Height & media
  // ---------------------------------------------------------------------------

  Future<void> updateEmbedPostHeight() async {
    try {
      final double? newHeight =
          await webViewController.getEmbedDocumentHeight();
      if (_isDisposed) return;
      if (newHeight != null && height != newHeight) {
        _logger.debug('Updated embed height for ${param.url} -> $newHeight');
        setHeight(newHeight);
      }
    } catch (error, stackTrace) {
      _logger.debug(
        'Failed to read embed height for ${param.url}',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> pauseMedias() async {
    if (param.isTikTokPhoto) {
      await webViewController.muteAudioWidget();
    } else {
      await webViewController.pauseVideos();
    }
  }

  Future<void> refresh() async {
    _logger.debug('Refreshing embed for ${param.url}');
    await webViewController.reload();
    _setLoadEmbedPostTimeoutFunction();
  }

  void _setLoadEmbedPostTimeoutFunction() {
    _timeoutTimer?.cancel();
    final timeout = config?.loadTimeout ?? const Duration(seconds: 10);
    _timeoutTimer = Timer(timeout, () {
      if (!_isDisposed && loadingState != EmbedLoadingState.loaded) {
        _logger.warning('Embed load timed out after $timeout for ${param.url}');
        setLoadingState(EmbedLoadingState.error);
      }
    });
  }
}
