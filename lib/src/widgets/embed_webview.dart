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
  State<EmbedWebView> createState() => _EmbedViewState();
}

class _EmbedViewState extends State<EmbedWebView> {
  static const _defaultVideoAspectRatio = 16 / 9;
  static const _defaultSpotifyHeight = 152.0;
  static const _defaultSoundCloudHeight = 166.0;
  static const _defaultContentFallbackHeight = 320.0;

  late EmbedWebViewDriver _driver;

  @override
  void initState() {
    super.initState();
    _driver = EmbedWebViewDriver(controller: widget.controller);
    _scheduleInit();
  }

  @override
  void didUpdateWidget(covariant EmbedWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged) {
      _driver.dispose();
      _driver = EmbedWebViewDriver(controller: widget.controller);
    }

    if (controllerChanged ||
        oldWidget.data != widget.data ||
        oldWidget.url != widget.url ||
        oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.scrollable != widget.scrollable ||
        oldWidget.param != widget.param) {
      _scheduleInit(forceReload: true);
    }
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
    _driver.dispose();
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
          onVisibilityChanged: (info) => widget.controller.updateVisibility(
            info.visibleFraction > 0,
            onVisibilityChange: (visible) {
              if (!visible && loadingState == EmbedLoadingState.loaded) {
                _driver.pauseMedias();
              }
            },
          ),
          child: webViewContainer,
        );
      },
    );
  }
}
