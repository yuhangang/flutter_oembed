import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/controllers/embed_navigation_handler.dart';
import 'package:flutter_oembed/src/core/provider_strategy.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter_oembed/src/utils/embed_webview_controller_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Internal driver that manages the low-level [WebViewController] interactions.
///
/// This class decouples the WebView lifecycle and platform-specific scripts
/// from the high-level [EmbedController] state. It handles loading HTML,
/// executing provider-specific strategies, intercepting navigation requests,
/// and coordinating media focus/playback when the widget enters or leaves
/// the viewport or is covered by a route.
class EmbedWebViewDriver {
  static const _initialRenderDelay = Duration(milliseconds: 300);
  static const _integrityRetryDelay = Duration(milliseconds: 700);
  static const _postLoadShiftDelay = Duration(milliseconds: 500);

  final EmbedController controller;
  final SocialEmbedParam param;
  final WebViewController webViewController;
  late final EmbedNavigationHandler _navigationHandler;
  static final _focusCoordinator = _EmbedFocusCoordinator();
  static final Object _defaultFocusGroup = Object();

  EmbedProviderStrategy _strategy = const GenericEmbedProviderStrategy();
  Object _focusGroupKey = _defaultFocusGroup;
  double _visibleFraction = 0;
  bool _isFocused = false;
  bool _isRouteCovered = false;
  bool _isDisposed = false;

  EmbedLogger get _logger =>
      controller.config?.logger ?? const EmbedLogger.disabled();

  EmbedWebViewDriver({
    required this.controller,
    required this.param,
    WebViewController? webViewController,
  }) : webViewController = webViewController ?? generateWebViewController() {
    final rule = EmbedService.resolveRule(
      param.url,
      config: controller.config,
    );
    controller.setMatchedProviderRule(rule);
    _strategy = rule?.strategy ?? const GenericEmbedProviderStrategy();

    controller.bindMediaControls(
      pause: () => pauseMedias(),
      resume: () => resumeMedias(),
      mute: () => muteMedias(),
      unmute: () => unmuteMedias(),
    );
    _navigationHandler = EmbedNavigationHandler(
      param: param,
      config: controller.config,
      providerRuleGetter: () => controller.matchedProviderRule,
    );
  }

  /// Disposes of the driver resources, unbinding from the focus coordinator
  /// and clearing the WebView if [preserveWebView] is false.
  void dispose({bool preserveWebView = false}) {
    if (_isDisposed) return;
    _isDisposed = true;
    controller.cancelLoadTimeout();
    controller.unbindMediaControls();
    _focusCoordinator.detach(this, groupKey: _focusGroupKey);
    if (!preserveWebView) {
      unawaited(_disposeWebView());
    }
  }

  /// Updates the navigation focus group based on the target [route].
  ///
  /// Used by the overarching focus coordinator to group multiple embeds under
  /// a single route, ensuring only the most visible one plays audio.
  void updateFocusGroup(ModalRoute<dynamic>? route) {
    if (_isDisposed) return;
    final nextGroupKey = route ?? _defaultFocusGroup;
    _updateFocusGroup(nextGroupKey);
  }

  /// Informs the driver whether the current route is entirely occluded by
  /// another full-screen overlay or route, pausing media if covered.
  Future<void> setRouteCovered(bool covered) async {
    if (_isDisposed || _isRouteCovered == covered) return;
    _isRouteCovered = covered;

    if (covered) {
      await pauseMedias(reason: 'route_covered');
    }
  }

  /// Reports the visibility fraction of this embed's widget.
  ///
  /// Values range from 0.0 (completely hidden) to 1.0 (fully visible).
  /// This value is used by [_EmbedFocusCoordinator] to automatically pause
  /// or resume media.
  void updateVisibilityFraction(double visibleFraction) {
    if (_isDisposed) return;
    final normalized = visibleFraction.clamp(0.0, 1.0).toDouble();
    _navigationHandler.isVisible = normalized > 0;
    if ((normalized - _visibleFraction).abs() < 0.01) return;
    _visibleFraction = normalized;

    _focusCoordinator.updateVisibility(
      this,
      groupKey: _focusGroupKey,
      visibleFraction: normalized,
    );
  }

  /// Records a manual user interaction with the embed.
  ///
  /// This interaction state is maintained to distinguish automated clicks
  /// from explicit user intent when evaluating navigation requests.
  void recordUserInteraction() {
    if (_isDisposed) return;
    _logger.debug('Recording user interaction');
    _navigationHandler.recordUserInteraction();
  }

  /// Initialises and loads the WebView.
  ///
  /// Re-evaluates the [EmbedProviderStrategy] and prepares the [WebViewController]
  /// environment (background color, zoom, user agent, channels, delegates)
  /// before loading either raw HTML or a URL based on the provided parameters.
  Future<void> initEmbedWebview({
    required Color backgroundColor,
    required EmbedData? embedData,
    required String? embedUrl,
    required double maxWidth,
    bool scrollable = false,
    bool forceReload = false,
  }) async {
    if (_isDisposed) return;
    final rule = EmbedService.resolveRule(
      param.url,
      config: controller.config,
    );
    controller.setMatchedProviderRule(rule);
    _strategy = rule?.strategy ?? const GenericEmbedProviderStrategy();

    if (!forceReload &&
        controller.loadingState == EmbedLoadingState.loaded &&
        (controller.height != null || param.embedType == EmbedType.tiktok_v1)) {
      _logger.debug('Embed already loaded, skipping initEmbedWebview');
      return;
    }

    _logger.debug('Initializing WebView', data: {
      'url': param.url,
      'strategy': _strategy.runtimeType.toString(),
    });

    await _initWebViewController(
      backgroundColor: backgroundColor,
      embedData: embedData,
      embedUrl: embedUrl,
      scrollable: scrollable,
    );
    if (_isDisposed) return;

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
    required String? embedUrl,
    bool scrollable = false,
  }) async {
    _navigationHandler.oembedData = embedData;

    await webViewController.setBackgroundColor(backgroundColor);
    if (_isDisposed) return;
    await webViewController.enableZoom(scrollable);
    if (_isDisposed) return;
    await webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (_isDisposed) return;

    final customUserAgent = _strategy.userAgent;
    if (customUserAgent != null) {
      await webViewController.setUserAgent(customUserAgent);
      if (_isDisposed) return;
    }

    await _strategy.onWebViewCreated(this);
    if (_isDisposed) return;

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
    if (_isDisposed) return;

    await webViewController.addJavaScriptChannel(
      'ErrorChannel',
      onMessageReceived: (JavaScriptMessage message) {
        if (_shouldIgnoreJavaScriptError(message.message)) {
          _logger.debug(
            'Ignoring non-fatal WebView JS error',
            data: {
              'url': param.url,
              'message': message.message,
            },
          );
          return;
        }

        _logger.warning('WebView JS error received', data: {
          'url': param.url,
          'message': message.message,
        });

        if (controller.loadingState == EmbedLoadingState.loaded) {
          return;
        }

        controller.setLoadingState(
          EmbedLoadingState.error,
          error: StateError('WebView JavaScript error: ${message.message}'),
        );
      },
    );
    if (_isDisposed) return;

    await webViewController.addJavaScriptChannel(
      'NavigationIntentChannel',
      onMessageReceived: (JavaScriptMessage message) {
        _navigationHandler.recordUserNavigationIntent(message.message);
      },
    );
    if (_isDisposed) return;

    final baseUrl = embedData?.providerUrl;
    final trustedMainFrameUrls = <String>[
      if (embedData?.url case final url? when url.isNotEmpty) url,
      if (embedUrl case final url? when url.isNotEmpty) url,
    ];

    await webViewController.setNavigationDelegate(
      _navigationHandler.buildDelegate(
        baseUrl: baseUrl,
        trustedMainFrameUrls: trustedMainFrameUrls,
        loadingStateGetter: () => controller.loadingState,
        onPageStarted: (url) async {
          await _strategy.onPageStarted(this);
        },
        onPageFinished: () async {
          await _strategy.onPageFinished(this);
          finalizePageFinished();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true) {
            _logger.warning('Main frame load error', data: {
              'url': param.url,
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

            controller.setLoadingState(
              isConnectionError
                  ? EmbedLoadingState.noConnection
                  : EmbedLoadingState.error,
              error: isConnectionError
                  ? EmbedNetworkException(
                      cause: error,
                      message: error.description,
                    )
                  : StateError(
                      'WebView load failed (${error.errorCode}): ${error.description}',
                    ),
            );
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
    if (_isDisposed) return;
    if (embedData != null) {
      if (embedData.html.isNotEmpty) {
        await webViewController.loadHtmlString(
          _strategy.buildHtmlDocument(
            embedData.html,
            type: param.embedType,
            maxWidth: maxWidth,
            scrollable: scrollable,
          ),
          baseUrl: _strategy.resolveBaseUrl(embedData),
        );
      } else if (embedData.url != null && embedData.url!.isNotEmpty) {
        if (_isDisposed) return;
        await webViewController.loadRequest(Uri.parse(embedData.url!));
      }
    } else if (embedUrl != null) {
      if (_isDisposed) return;
      final embedUri = Uri.parse(embedUrl);
      final refererHeader = param.embedType == EmbedType.youtube &&
              (embedUri.host.contains('youtube.com') ||
                  embedUri.host.contains('youtube-nocookie.com'))
          ? embedUri.origin
          : param.url;
      await webViewController.loadRequest(
        embedUri,
        headers: <String, String>{
          if (param.embedType == EmbedType.youtube ||
              param.embedType == EmbedType.spotify)
            'Referer': refererHeader,
        },
      );
    }
  }

  Future<void> finalizePageFinished() async {
    // 1. URL Safety Check: If we end up on an error page or unexpected blank page, trigger error
    final url = await webViewController.currentUrl();
    if (_isDisposed) return;
    if (url != null &&
        (url.startsWith('chrome-error:') ||
            (url.startsWith('file://') && url.contains('ERROR')))) {
      _logger.warning('WebView loaded an error page', data: {
        'url': param.url,
        'currentUrl': url,
      });
      controller.setLoadingState(
        EmbedLoadingState.error,
        error: StateError('WebView loaded an error page: $url'),
      );
      return;
    }

    // 2. Small delay to allow initial rendering to start
    if (!await _delayWhileActive(_initialRenderDelay)) return;

    if (controller.loadingState != EmbedLoadingState.loaded) {
      // 3. Initial height check
      await updateEmbedPostHeight();
      if (_isDisposed) return;

      if (controller.height != null && controller.height! > 1.0) {
        controller.cancelLoadTimeout();
        controller.setLoadingState(EmbedLoadingState.loaded);
      }
    }

    // ----- Generic path -----
    // 4. Post-Load Integrity Check: If height is still effectively 0 after small delay,
    // it might be a silent failure (e.g. script crashed before rendering anything)
    if (controller.height == null || controller.height! <= 1.0) {
      if (!await _delayWhileActive(_integrityRetryDelay)) return;
      await updateEmbedPostHeight();
      if (_isDisposed) return;

      if (controller.height != null && controller.height! > 0) {
        controller.cancelLoadTimeout();
        controller.setLoadingState(EmbedLoadingState.loaded);
      } else {
        _logger.warning('WebView load integrity failure: effectively 0 height',
            data: {
              'url': param.url,
            });
        controller.setLoadingState(
          EmbedLoadingState.error,
          error: StateError(
            'WebView rendered with an invalid height for ${param.url}.',
          ),
        );
      }
    }

    // Final short delay to catch any immediate post-load shifts
    if (!await _delayWhileActive(_postLoadShiftDelay)) return;

    await updateEmbedPostHeight();
  }

  /// Polls the document height from the WebView and updates the controller
  /// if a change is detected.
  Future<void> updateEmbedPostHeight() async {
    try {
      final double? newHeight =
          await webViewController.getEmbedDocumentHeight();
      if (_isDisposed) return;
      if (newHeight != null && controller.height != newHeight) {
        _logger.debug(
          'Updated embed height',
          data: {
            'url': param.url,
            'height': newHeight,
          },
        );
        controller.setHeight(newHeight);
      }
    } catch (error, stackTrace) {
      _logger.debug(
        'Failed to read embed height',
        data: {'url': param.url},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Pauses active media playback via the provider-specific strategy.
  Future<void> pauseMedias({String reason = 'manual'}) async {
    await _controlMedia(
      action: _MediaControlAction.pause,
      reason: reason,
    );
  }

  /// Resumes media playback via the provider-specific strategy.
  Future<void> resumeMedias({String reason = 'manual'}) async {
    await _controlMedia(
      action: _MediaControlAction.resume,
      reason: reason,
    );
  }

  /// Mutes audio via the provider-specific strategy.
  Future<void> muteMedias({String reason = 'manual'}) async {
    await _controlMedia(
      action: _MediaControlAction.mute,
      reason: reason,
    );
  }

  /// Unmutes audio via the provider-specific strategy.
  Future<void> unmuteMedias({String reason = 'manual'}) async {
    await _controlMedia(
      action: _MediaControlAction.unmute,
      reason: reason,
    );
  }

  /// Reloads the underlying [WebViewController] to trigger a fresh page load.
  Future<void> refresh() async {
    _logger.debug('Refreshing embed', data: {'url': param.url});
    if (_isDisposed) return;
    await webViewController.reload();
    if (_isDisposed) return;
    controller.startLoadTimeout();
  }

  Future<bool> _delayWhileActive(Duration duration) async {
    await Future.delayed(duration);
    return !_isDisposed;
  }

  void _updateFocusGroup(Object nextGroupKey) {
    if (identical(nextGroupKey, _focusGroupKey)) return;
    _focusCoordinator.detach(this, groupKey: _focusGroupKey);
    _focusGroupKey = nextGroupKey;
    if (_visibleFraction > 0) {
      _focusCoordinator.updateVisibility(
        this,
        groupKey: _focusGroupKey,
        visibleFraction: _visibleFraction,
      );
    }
  }

  /// Called by the [_EmbedFocusCoordinator] to signal that this driver has
  /// gained or lost dominant focus among its peers in the same route.
  void onFocusChanged(
    bool focused, {
    required String reason,
    bool forcePause = false,
  }) {
    if (_isDisposed) return;
    final wasFocused = _isFocused;
    _isFocused = focused;

    if (focused == wasFocused && !forcePause) {
      return;
    }

    _logger.info(
      'Embed focus changed',
      data: {
        'url': param.url,
        'focused': focused,
        'reason': reason,
        'visibleFraction': _visibleFraction,
      },
    );

    if (controller.loadingState != EmbedLoadingState.loaded) {
      return;
    }

    if (!focused || forcePause || _visibleFraction <= 0) {
      unawaited(pauseMedias(reason: reason));
    }
  }

  Future<void> _controlMedia({
    required _MediaControlAction action,
    required String reason,
    Duration? position,
  }) async {
    if (_isDisposed || controller.loadingState != EmbedLoadingState.loaded) {
      return;
    }

    _logger.info(
      'Media control requested',
      data: {
        'url': param.url,
        'action': action.name,
        'reason': reason,
        'strategy': _strategy.runtimeType.toString(),
        'focused': _isFocused,
        'visibleFraction': _visibleFraction,
        'routeCovered': _isRouteCovered,
        if (position != null) 'positionMs': position.inMilliseconds,
      },
    );

    try {
      switch (action) {
        case _MediaControlAction.pause:
          await _strategy.mediaStrategy?.pauseMedia(webViewController);
        case _MediaControlAction.resume:
          await _strategy.mediaStrategy?.resumeMedia(webViewController);
        case _MediaControlAction.mute:
          await _strategy.mediaStrategy?.muteMedia(webViewController);
        case _MediaControlAction.unmute:
          await _strategy.mediaStrategy?.unmuteMedia(webViewController);
      }
    } catch (error, stackTrace) {
      _logger.warning(
        'Media control failed',
        data: {
          'url': param.url,
          'action': action.name,
          'reason': reason,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _disposeWebView() async {
    try {
      await webViewController.loadRequest(Uri.parse('about:blank'));
    } catch (error, stackTrace) {
      _logger.debug(
        'Ignoring WebView cleanup load failure during dispose',
        data: {'url': param.url},
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await webViewController.setNavigationDelegate(NavigationDelegate());
    } catch (error, stackTrace) {
      _logger.debug(
        'Ignoring NavigationDelegate cleanup failure during dispose',
        data: {'url': param.url},
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _shouldIgnoreJavaScriptError(String message) {
    final normalized = message.trim().toLowerCase();

    // Cross-origin iframes often surface this opaque browser error even when
    // the embed itself is functioning. Treating it as fatal breaks later media
    // controls and route-cover pause behavior.
    if (normalized.contains('js_error: script error. at :0')) {
      return true;
    }

    if (normalized == 'js_error: script error.') {
      return true;
    }

    return false;
  }
}

enum _MediaControlAction { pause, resume, mute, unmute }

/// Internal coordinator that tracks visibility for multiple [EmbedWebViewDriver]s
/// grouped by route/container. It automatically plays media for the single
/// most visible embed and pauses the others.
class _EmbedFocusCoordinator {
  final Map<Object, Map<EmbedWebViewDriver, double>> _visibleFractionsByGroup =
      <Object, Map<EmbedWebViewDriver, double>>{};
  final Map<Object, EmbedWebViewDriver> _focusedByGroup =
      <Object, EmbedWebViewDriver>{};

  void updateVisibility(
    EmbedWebViewDriver driver, {
    required Object groupKey,
    required double visibleFraction,
  }) {
    final group = _visibleFractionsByGroup.putIfAbsent(
      groupKey,
      () => <EmbedWebViewDriver, double>{},
    );

    if (visibleFraction <= 0) {
      group.remove(driver);
    } else {
      group[driver] = visibleFraction;
    }

    final nextFocused = _pickFocused(group, _focusedByGroup[groupKey]);
    final prevFocused = _focusedByGroup[groupKey];

    if (nextFocused == null) {
      if (prevFocused != null) {
        prevFocused.onFocusChanged(false, reason: 'focus_none_visible');
      }
      _focusedByGroup.remove(groupKey);
      _visibleFractionsByGroup.remove(groupKey);
      return;
    }

    if (!identical(prevFocused, nextFocused)) {
      if (prevFocused != null) {
        prevFocused.onFocusChanged(false, reason: 'focus_transferred');
      }
      _focusedByGroup[groupKey] = nextFocused;
      nextFocused.onFocusChanged(true, reason: 'focus_acquired');
    }

    if (!identical(driver, nextFocused) && visibleFraction > 0) {
      driver.onFocusChanged(
        false,
        reason: 'focus_not_primary',
        forcePause: true,
      );
    }
  }

  void detach(EmbedWebViewDriver driver, {Object? groupKey}) {
    if (groupKey != null) {
      _detachFromGroup(driver, groupKey);
      return;
    }

    final keys = _visibleFractionsByGroup.keys.toList();
    for (final key in keys) {
      _detachFromGroup(driver, key);
    }
  }

  void _detachFromGroup(EmbedWebViewDriver driver, Object groupKey) {
    final group = _visibleFractionsByGroup[groupKey];
    if (group == null) return;

    group.remove(driver);
    final wasFocused = identical(_focusedByGroup[groupKey], driver);

    if (group.isEmpty) {
      _visibleFractionsByGroup.remove(groupKey);
      _focusedByGroup.remove(groupKey);
      return;
    }

    if (wasFocused) {
      final nextFocused = _pickFocused(group, null);
      if (nextFocused == null) {
        _focusedByGroup.remove(groupKey);
        return;
      }
      _focusedByGroup[groupKey] = nextFocused;
      nextFocused.onFocusChanged(true, reason: 'focus_rebalanced');
    }
  }

  EmbedWebViewDriver? _pickFocused(
    Map<EmbedWebViewDriver, double> group,
    EmbedWebViewDriver? currentFocused,
  ) {
    if (group.isEmpty) return null;
    EmbedWebViewDriver? winner = currentFocused;
    double winnerFraction = winner != null ? (group[winner] ?? -1) : -1;

    group.forEach((driver, fraction) {
      if (fraction > winnerFraction) {
        winner = driver;
        winnerFraction = fraction;
      }
    });

    return winner;
  }
}

@visibleForTesting
void resetEmbedFocusCoordinatorForTests() {
  EmbedWebViewDriver._focusCoordinator._visibleFractionsByGroup.clear();
  EmbedWebViewDriver._focusCoordinator._focusedByGroup.clear();
}

@visibleForTesting
bool embedDriverHasRecentUserInteraction(EmbedWebViewDriver driver) =>
    driver._navigationHandler.hasRecentUserInteractionForTesting;

@visibleForTesting
bool embedDriverNavigationIsVisible(EmbedWebViewDriver driver) =>
    driver._navigationHandler.isVisible;
