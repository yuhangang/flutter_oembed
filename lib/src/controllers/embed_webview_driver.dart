import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/controllers/embed_navigation_handler.dart';
import 'package:flutter_embed/src/core/provider_strategy.dart';
import 'package:flutter_embed/src/logging/embed_logger.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/services/embed_service.dart';
import 'package:flutter_embed/src/utils/embed_webview_controller_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Internal driver that manages the low-level [WebViewController] interactions.
///
/// This class decouples the WebView lifecycle and platform-specific scripts
/// from the high-level [EmbedController] state.
class EmbedWebViewDriver {
  final EmbedController controller;
  final WebViewController webViewController;
  late final EmbedNavigationHandler _navigationHandler;
  EmbedProviderStrategy _strategy = const GenericEmbedProviderStrategy();
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
    // Resolve strategy first
    final rule = EmbedService.resolveRule(
      controller.param.url,
      config: controller.config,
    );
    _strategy = rule?.strategy ?? const GenericEmbedProviderStrategy();

    if (!forceReload &&
        controller.loadingState == EmbedLoadingState.loaded &&
        (controller.height != null ||
            controller.param.embedType == EmbedType.tiktok)) {
      return;
    }

    _logger.debug('Initializing WebView', data: {
      'url': controller.param.url,
      'strategy': _strategy.runtimeType.toString(),
    });

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

    final customUserAgent = _strategy.userAgent;
    if (customUserAgent != null) {
      webViewController.setUserAgent(customUserAgent);
    }

    await _strategy.onWebViewCreated(
      webViewController,
      onTwitterLoaded: () async {
        await updateEmbedPostHeight();
        if (controller.loadingState != EmbedLoadingState.loaded &&
            controller.height != null &&
            controller.height! > 0) {
          controller.cancelLoadTimeout();
          controller.setLoadingState(EmbedLoadingState.loaded);
        }
      },
    );

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

    await webViewController.addJavaScriptChannel(
      'ErrorChannel',
      onMessageReceived: (JavaScriptMessage message) {
        _logger.warning('WebView JS error received', data: {
          'url': controller.param.url,
          'message': message.message,
        });
        controller.setLoadingState(EmbedLoadingState.error);
      },
    );

    final baseUrl = embedData?.providerUrl;

    await webViewController.setNavigationDelegate(
      _navigationHandler.buildDelegate(
        baseUrl: baseUrl,
        loadingStateGetter: () => controller.loadingState,
        onPageStarted: (url) async {
          await _strategy.onPageStarted(webViewController);
        },
        onPageFinished: () async {
          await _strategy.onPageFinished(webViewController);
          await _handleEmbedPageFinished();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) {
            _logger.warning('Main frame load error', data: {
              'url': controller.param.url,
              'errorCode': error.errorCode,
              'description': error.description,
            });

            // Handle specific error codes if needed
            // Common network errors: -2 (lookup failed), -6 (connection timed out), -8 (host unreachable)
            // SSL/TLS errors: -100 to -199
            // NSURLErrorDomain (iOS): -1001 (Timed Out), -1003 (DNS), -1004 (Cannot connect),
            // -1005 (Lost connection), -1009 (No internet), -1200 (SSL)
            final isConnectionError = error.errorCode == -2 ||
                error.errorCode == -6 ||
                error.errorCode == -8 ||
                error.errorCode == -1001 ||
                error.errorCode == -1003 ||
                error.errorCode == -1004 ||
                error.errorCode == -1005 ||
                error.errorCode == -1009 ||
                error.errorCode == -1200 ||
                (error.errorCode >= -199 && error.errorCode <= -100) ||
                error.description.toLowerCase().contains('internet') ||
                error.description.toLowerCase().contains('connection') ||
                error.description.toLowerCase().contains('timeout');

            controller.setLoadingState(isConnectionError
                ? EmbedLoadingState.noConnection
                : EmbedLoadingState.error);
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
          _strategy.buildHtmlDocument(
            resolvedData.html,
            type: controller.param.embedType,
            maxWidth: maxWidth,
            scrollable: scrollable,
          ),
          baseUrl: _strategy.resolveBaseUrl(resolvedData),
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
    // 1. URL Safety Check: If we end up on an error page or unexpected blank page, trigger error
    final url = await webViewController.currentUrl();
    if (url != null &&
        (url.startsWith('chrome-error:') ||
            (url.startsWith('file://') && url.contains('ERROR')))) {
      _logger.warning('WebView loaded an error page', data: {
        'url': controller.param.url,
        'currentUrl': url,
      });
      controller.setLoadingState(EmbedLoadingState.error);
      return;
    }

    // 2. Small delay to allow initial rendering to start
    await Future.delayed(const Duration(milliseconds: 300));
    if (_isDisposed) return;

    if (controller.loadingState != EmbedLoadingState.loaded) {
      if (_strategy.deferLoadingState) {
        // ----- Deferred path (e.g. X/Twitter) -----
        // The provider has its own "loaded" signal (e.g. OnTwitterLoaded JS
        // channel). Wait up to 2 seconds for it to fire. If the signal
        // arrives, the callback will have already set state to loaded.
        await Future.delayed(const Duration(seconds: 2));
        if (_isDisposed) return;
        if (controller.loadingState == EmbedLoadingState.loaded) return;

        // Fallback: signal didn't arrive in time – use height-based detection
        await updateEmbedPostHeight();
        if (_isDisposed) return;

        if (controller.height != null && controller.height! > 0) {
          controller.setLoadingState(EmbedLoadingState.loaded);
        } else {
          _logger.warning(
            'Deferred embed load: signal not received and height is 0',
            data: {'url': controller.param.url},
          );
          controller.setLoadingState(EmbedLoadingState.error);
        }
        return;
      } else {
        // 3. Initial height check
        await updateEmbedPostHeight();
        if (_isDisposed) return;
      }

      // ----- Generic path -----
      // 4. Post-Load Integrity Check: If height is still effectively 0 after small delay,
      // it might be a silent failure (e.g. script crashed before rendering anything)
      if (controller.height == null || controller.height! <= 1.0) {
        await Future.delayed(const Duration(milliseconds: 700));
        await updateEmbedPostHeight();
      }

      if (controller.height != null && controller.height! > 0) {
        controller.cancelLoadTimeout();
        controller.setLoadingState(EmbedLoadingState.loaded);
      } else {
        _logger.warning('WebView load integrity failure: effectively 0 height',
            data: {
              'url': controller.param.url,
            });
        controller.setLoadingState(EmbedLoadingState.error);
      }

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
    await _strategy.pauseMedia(webViewController);
  }

  Future<void> refresh() async {
    _logger.debug('Refreshing embed', data: {'url': controller.param.url});
    await webViewController.reload();
    controller.startLoadTimeout();
  }
}
