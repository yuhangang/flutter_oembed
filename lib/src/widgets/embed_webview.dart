import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';
import 'package:flutter_oembed/src/models/embed_constraints.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_strings.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/controllers/embed_webview_driver.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbedWebView extends StatefulWidget {
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
  final Object? reuseKey;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

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
    this.reuseKey,
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
    this.reuseKey,
    this.webViewBuilder,
  })  : assert(
          embedConstraints == null || embedHeight == null,
          'Use either embedConstraints or embedHeight, not both.',
        ),
        data = null;

  @override
  State<EmbedWebView> createState() => _EmbedViewState();
}

class _EmbedViewState extends State<EmbedWebView> {
  static const _defaultVideoAspectRatio = 16 / 9;
  static const _defaultSpotifyHeight = 152.0;
  static const _defaultSoundCloudHeight = 166.0;
  static const _defaultContentFallbackHeight = 320.0;

  late EmbedWebViewDriver _driver;
  Object? _reuseScopeToken;
  bool _reuseWebViewsEnabled = false;

  _EmbedWebViewReuseSignature get _reuseSignature =>
      _EmbedWebViewReuseSignature(
        param: widget.param,
        data: widget.data,
        url: widget.url,
      );

  @override
  void initState() {
    super.initState();
    _captureReuseScope(listen: false);
    _driver = _createDriver();
    _scheduleInit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _captureReuseScope();
  }

  @override
  void didUpdateWidget(covariant EmbedWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged = oldWidget.controller != widget.controller;
    final shouldRefresh = controllerChanged ||
        oldWidget.data != widget.data ||
        oldWidget.url != widget.url ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.scrollable != widget.scrollable ||
        oldWidget.param != widget.param ||
        oldWidget.reuseKey != widget.reuseKey;

    if (shouldRefresh) {
      _driver.dispose();
      _driver = _createDriver();
      _scheduleInit(forceReload: true);
    }
  }

  EmbedWebViewDriver _createDriver() {
    final reusedController = widget.reuseKey != null && _reuseWebViewsEnabled
        ? EmbedScope.takeReusedWebViewControllerFromToken(
            _reuseScopeToken,
            reuseKey: widget.reuseKey!,
            signature: _reuseSignature,
          )
        : null;
    return EmbedWebViewDriver(
      controller: widget.controller,
      webViewController: reusedController,
    );
  }

  void _captureReuseScope({bool listen = true}) {
    _reuseScopeToken = EmbedScope.reuseScopeTokenOf(context, listen: listen);
    _reuseWebViewsEnabled = _reuseScopeToken != null &&
        EmbedScope.reuseWebViewsOf(context, listen: listen);
  }

  void _scheduleInit({bool forceReload = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final bg = Theme.of(context).scaffoldBackgroundColor;
      await _driver.initEmbedWebview(
        backgroundColor: bg,
        embedData: widget.data,
        embedUrl: widget.url,
        maxWidth: widget.maxWidth,
        scrollable: widget.scrollable,
        forceReload: forceReload,
      );
    });
  }

  @override
  void dispose() {
    var preserveWebView = false;
    if (widget.reuseKey != null && _reuseWebViewsEnabled) {
      EmbedScope.releaseReusedWebViewControllerToToken(
        _reuseScopeToken,
        reuseKey: widget.reuseKey!,
        signature: _reuseSignature,
        controller: _driver.webViewController,
      );
      preserveWebView = true;
    }
    _driver.dispose(preserveWebView: preserveWebView);
    super.dispose();
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
      child: WebViewWidget(
        controller: _driver.webViewController,
        gestureRecognizers: gestureRecognizers,
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
                      if (loadingState == EmbedLoadingState.error) {
                        widget.controller.setDidRetry();
                        _driver.refresh();
                      } else {
                        _driver.webViewController.reload();
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
          webViewContainer = effectiveWebViewBuilder(context, webViewContainer);
        }

        return VisibilityDetector(
          key: ValueKey(widget.param),
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

@immutable
class _EmbedWebViewReuseSignature {
  const _EmbedWebViewReuseSignature({
    required this.param,
    required this.data,
    required this.url,
  });

  final SocialEmbedParam param;
  final EmbedData? data;
  final String? url;

  @override
  bool operator ==(Object other) {
    return other is _EmbedWebViewReuseSignature &&
        other.param == param &&
        other.data == data &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(param, data, url);
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
    final routeObserver = config?.routeObserver;
    final route = ModalRoute.of(context);

    if (routeObserver != _routeObserver) {
      _routeObserver?.unsubscribe(this);
      _routeObserver = routeObserver;
      if (routeObserver != null && route != null) {
        routeObserver.subscribe(this, route);
      }
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
    widget.driver.setRouteCovered(true);
  }

  @override
  void didPopNext() {
    widget.driver.setRouteCovered(false);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
