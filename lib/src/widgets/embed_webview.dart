import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/controllers/embed_webview_driver.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_strings.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/models/embed_webview_controls.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Renders embedded social media content in a platform WebView.
///
/// This is a thin stateless wrapper around [_EmbedWebViewCore]. It uses a
/// [ListenableBuilder] to observe the [controller] and keys the inner widget
/// on a composite [ValueKey] that captures all content-affecting inputs:
///
///  * Controller identity (via [identityHashCode])
///  * [EmbedController.embedRevision] (bumped by [EmbedController.synchronize])
///  * [param], [data], [url], [maxWidth], [scrollable]
///
/// When any of these change, Flutter tears down the old [_EmbedWebViewCore]
/// state and creates a fresh one — giving a clean [State.initState] with no
/// need for [State.didUpdateWidget] or manual staleness detection.
///
/// Display-only props ([style], [webViewBuilder], [embedConstraints]) are
/// intentionally excluded from the key so they can change without a full
/// WebView teardown.
class EmbedWebView extends StatelessWidget {
  final SocialEmbedParam param;
  final EmbedData? data;
  final String? url;
  final double maxWidth;
  final EmbedConstraints? embedConstraints;
  @Deprecated(
    'Use embedConstraints: EmbedConstraints(preferredHeight: ...) instead.',
  )
  final double? embedHeight;
  final EmbedController controller;
  final EmbedStyle? style;
  final bool scrollable;
  final Widget Function(
    BuildContext context,
    EmbedWebViewControls controls,
    Widget child,
  )? webViewBuilder;

  const EmbedWebView.data({
    super.key,
    required this.param,
    required EmbedData this.data,
    required this.maxWidth,
    this.embedConstraints,
    this.embedHeight,
    required this.controller,
    this.style,
    this.scrollable = false,
    this.webViewBuilder,
  })  : assert(
          embedConstraints == null || embedHeight == null,
          'Use either embedConstraints or embedHeight, not both.',
        ),
        url = null;

  const EmbedWebView.url({
    super.key,
    required this.param,
    required String this.url,
    required this.maxWidth,
    this.embedConstraints,
    this.embedHeight,
    required this.controller,
    this.style,
    this.scrollable = false,
    this.webViewBuilder,
  })  : assert(
          embedConstraints == null || embedHeight == null,
          'Use either embedConstraints or embedHeight, not both.',
        ),
        data = null;

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds when controller notifies (e.g. synchronize).
    // The composite ValueKey on the inner widget causes a full state reset
    // whenever the controller identity, embed revision, or content-affecting
    // props change — eliminating the need for didUpdateWidget or staleness
    // detection entirely.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return _EmbedWebViewCore(
          key: ValueKey((
            identityHashCode(controller),
            controller.embedRevision,
            param,
            data,
            url,
            maxWidth,
            scrollable,
          )),
          param: param,
          data: data,
          url: url,
          maxWidth: maxWidth,
          embedConstraints: embedConstraints,
          // ignore: deprecated_member_use_from_same_package
          embedHeight: embedHeight,
          controller: controller,
          style: style,
          scrollable: scrollable,
          webViewBuilder: webViewBuilder,
        );
      },
    );
  }
}

/// Internal stateful widget that owns the [EmbedWebViewDriver] lifecycle.
///
/// Keyed by the outer [EmbedWebView] on content-affecting props, so a prop
/// change destroys this state and creates a fresh one. This keeps the
/// lifecycle simple: [initState] creates the driver, [dispose] is a no-op
/// (the driver is owned by the controller for cross-mount persistence).
class _EmbedWebViewCore extends StatefulWidget {
  final SocialEmbedParam param;
  final EmbedData? data;
  final String? url;
  final double maxWidth;
  final EmbedConstraints? embedConstraints;
  final double? embedHeight;
  final EmbedController controller;
  final EmbedStyle? style;
  final bool scrollable;
  final Widget Function(
    BuildContext context,
    EmbedWebViewControls controls,
    Widget child,
  )? webViewBuilder;

  const _EmbedWebViewCore({
    super.key,
    required this.param,
    required this.data,
    required this.url,
    required this.maxWidth,
    this.embedConstraints,
    this.embedHeight,
    required this.controller,
    this.style,
    this.scrollable = false,
    this.webViewBuilder,
  });

  @override
  State<_EmbedWebViewCore> createState() => _EmbedWebViewCoreState();
}

class _EmbedWebViewCoreState extends State<_EmbedWebViewCore> {
  static const _defaultVideoAspectRatio = 16 / 9;
  static const _defaultSpotifyHeight = 152.0;
  static const _defaultSoundCloudHeight = 166.0;
  static const _defaultContentFallbackHeight = 320.0;

  /// The driver is created once in [initState] and never reassigned.
  /// When content-affecting props change, [EmbedWebView] generates a new key
  /// for the core widget, causing Flutter to destroy this state and create a
  /// fresh one with a new driver.
  late final EmbedWebViewDriver _driver;

  @override
  void initState() {
    super.initState();
    _driver = _createDriver();
    _scheduleVisibilityCheck();
    _scheduleInit();
  }

  @override
  void dispose() {
    super.dispose();
  }

  EmbedWebViewDriver _createDriver() {
    final existing = widget.controller.boundDriver;
    final controllerParam = widget.controller.param;
    if (existing is EmbedWebViewDriver) {
      if (existing.controller.param == controllerParam) {
        return existing;
      }
      // Parameters mismatch: unbind and dispose the old driver.
      widget.controller.unbindDriver();
      existing.dispose();
    }

    final driver = EmbedWebViewDriver(
      controller: widget.controller,
    );
    widget.controller.bindDriver(
      driver,
      onDispose: () => driver.dispose(),
    );
    return driver;
  }

  void _scheduleInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final bg = Theme.of(context).scaffoldBackgroundColor;
      await _driver.initEmbedWebview(
        backgroundColor: bg,
        embedData: widget.data,
        embedUrl: widget.url,
        maxWidth: widget.maxWidth,
        scrollable: widget.scrollable,
        forceReload: true,
      );
    });
  }

  void _scheduleVisibilityCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VisibilityDetectorController.instance.notifyNow();
    });
  }

  Widget _buildLoadingOverlay(
    BuildContext context,
    EmbedStyle? style,
    EmbedStrings strings,
  ) {
    final loadingChild = style?.loadingBuilder?.call(context) ??
        const Center(child: CircularProgressIndicator());
    return Semantics(
      container: true,
      liveRegion: true,
      label: strings.loadingSemanticsLabel,
      child: loadingChild,
    );
  }

  Widget _buildWebView(
    BuildContext context,
    EmbedStyle? style,
    EmbedStrings strings,
  ) {
    final gestureRecognizers = widget.scrollable
        ? <Factory<OneSequenceGestureRecognizer>>{
            const Factory<OneSequenceGestureRecognizer>(
              EagerGestureRecognizer.new,
            ),
          }
        : const <Factory<OneSequenceGestureRecognizer>>{};

    return Semantics(
      container: true,
      label: strings.contentSemanticsLabel,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _driver.recordUserInteraction(),
        child: WebViewWidget(
          controller: _driver.webViewController,
          gestureRecognizers: gestureRecognizers,
        ),
      ),
    );
  }

  String _retrySemanticsLabel(EmbedLoadingState state, EmbedStrings strings) {
    return switch (state) {
      EmbedLoadingState.noConnection =>
        strings.retryAfterConnectionErrorSemanticsLabel,
      _ => strings.retryAfterLoadErrorSemanticsLabel,
    };
  }

  double _fallbackHeight() {
    switch (widget.param.embedType) {
      case EmbedType.spotify:
        return _defaultSpotifyHeight;
      case EmbedType.soundcloud:
        return _defaultSoundCloudHeight;
      default:
        if (widget.param.embedType.isVideo) {
          return widget.maxWidth / _defaultVideoAspectRatio;
        }
        return math.min(widget.maxWidth, _defaultContentFallbackHeight);
    }
  }

  EmbedConstraints? get _effectiveEmbedConstraints =>
      widget.embedConstraints ??
      (widget.embedHeight != null
          ? EmbedConstraints(preferredHeight: widget.embedHeight)
          : null);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final effectiveParam = widget.controller.param;
        final config = widget.controller.config ?? EmbedScope.configOf(context);
        final style = widget.style ?? config?.style;
        final strings = config?.strings ?? const EmbedStrings();
        final loadingState = widget.controller.loadingState;
        final embedConstraints = _effectiveEmbedConstraints;
        final measuredHeight = widget.controller.height;
        final double? aspectRatio = widget.data?.aspectRatio ??
            widget.controller.preloadedData?.aspectRatio;

        double height = embedConstraints?.preferredHeight ??
            measuredHeight ??
            (aspectRatio != null
                ? widget.maxWidth / aspectRatio
                : _fallbackHeight());

        if (embedConstraints != null) {
          height = embedConstraints.clampHeight(height);
        } else if (widget.scrollable) {
          final maxScrollableHeight =
              style?.maxScrollableHeight ?? kDefaultMaxScrollableEmbedHeight;
          height = height.clamp(0.0, maxScrollableHeight).toDouble();
        }

        final effectiveWebViewBuilder =
            widget.webViewBuilder ?? style?.webViewBuilder;

        Widget webViewContainer = SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _EmbedWebviewObserver(
                driver: _driver,
                controller: widget.controller,
              ),
              _buildWebView(context, style, strings),
              if (loadingState == EmbedLoadingState.loading)
                _buildLoadingOverlay(context, style, strings)
              else if (loadingState == EmbedLoadingState.error ||
                  loadingState == EmbedLoadingState.noConnection)
                Semantics(
                  container: true,
                  liveRegion: true,
                  button: true,
                  enabled: true,
                  label: _retrySemanticsLabel(loadingState, strings),
                  hint: strings.retryHint,
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.setLoadingState(
                        EmbedLoadingState.loading,
                      );
                      if (loadingState == EmbedLoadingState.error ||
                          loadingState == EmbedLoadingState.noConnection) {
                        widget.controller.setDidRetry();
                        _driver.refresh();
                      }
                    },
                    child: style?.errorBuilder?.call(
                          context,
                          widget.controller.lastError,
                        ) ??
                        const Icon(Icons.refresh),
                  ),
                ),
            ],
          ),
        );

        if (effectiveWebViewBuilder != null) {
          final controls = EmbedWebViewControls(
            controller: _driver.webViewController,
            onReload: () => _driver.refresh(),
            onUpdateHeight: () => _driver.updateEmbedPostHeight(),
            onPause: () => widget.controller.pauseMedia(),
            onResume: () => widget.controller.resumeMedia(),
            onMute: () => widget.controller.muteMedia(),
            onUnmute: () => widget.controller.unmuteMedia(),
          );
          webViewContainer = effectiveWebViewBuilder(
            context,
            controls,
            webViewContainer,
          );
        }

        return VisibilityDetector(
          key: ValueKey(
            'embed_webview_${widget.controller.embedRevision}_${effectiveParam.key}',
          ),
          onVisibilityChanged: (info) {
            widget.controller.updateVisibility(
              info.visibleFraction > 0,
              onVisibilityChange: (_) {},
            );
            _driver.updateVisibilityFraction(info.visibleFraction);
          },
          child: webViewContainer,
        );
      },
    );
  }
}

class _EmbedWebviewObserver extends StatefulWidget {
  final EmbedWebViewDriver driver;
  final EmbedController controller;

  const _EmbedWebviewObserver({
    required this.driver,
    required this.controller,
  });

  @override
  State<_EmbedWebviewObserver> createState() => _EmbedWebviewObserverState();
}

class _EmbedWebviewObserverState extends State<_EmbedWebviewObserver>
    with RouteAware {
  RouteObserver<ModalRoute<dynamic>>? _routeObserver;
  bool _pauseOnRouteCover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSubscription();
  }

  @override
  void didUpdateWidget(_EmbedWebviewObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driver != widget.driver ||
        oldWidget.controller != widget.controller) {
      _updateSubscription();
    }
  }

  void _updateSubscription() {
    if (!mounted) return;

    final config = widget.controller.config ?? EmbedScope.configOf(context);
    final pauseOnRouteCover = config?.pauseOnRouteCover ?? false;
    final routeObserver = pauseOnRouteCover ? config?.routeObserver : null;
    final route = ModalRoute.of(context);
    final wasPauseOnRouteCover = _pauseOnRouteCover;
    _pauseOnRouteCover = pauseOnRouteCover;

    if (routeObserver != _routeObserver) {
      _routeObserver?.unsubscribe(this);
      _routeObserver = routeObserver;
      if (routeObserver != null && route != null) {
        routeObserver.subscribe(this, route);
      }
    }

    if (wasPauseOnRouteCover && !pauseOnRouteCover) {
      widget.driver.setRouteCovered(false);
    }

    widget.driver.updateFocusGroup(route);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    if (!_pauseOnRouteCover) return;
    widget.driver.setRouteCovered(true);
  }

  @override
  void didPopNext() {
    if (!_pauseOnRouteCover) return;
    widget.driver.setRouteCovered(false);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
