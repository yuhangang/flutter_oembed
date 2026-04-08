import 'dart:io';

import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/models/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_webview.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';

class EmbedDataLoader extends StatefulWidget {
  final SocialEmbedParam param;
  final EmbedLoaderParam loaderParam;
  final EmbedController controller;
  final EmbedConfig? config;
  final EmbedStyle? style;
  final EmbedCacheConfig? cacheConfig;
  final bool scrollable;
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  const EmbedDataLoader({
    super.key,
    required this.param,
    required this.loaderParam,
    required this.controller,
    this.config,
    this.style,
    this.cacheConfig,
    this.scrollable = false,
    this.webViewBuilder,
  });

  @override
  State<EmbedDataLoader> createState() => _EmbedDataLoaderState();
}

class _EmbedDataLoaderState extends State<EmbedDataLoader> {
  Future<EmbedData>? _embedFeature;
  EmbedConfig? _resolvedConfig;

  @override
  void initState() {
    super.initState();
    _loadData(config: widget.config);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final config = widget.config ?? EmbedScope.configOf(context);

    if (_resolvedConfig != config) {
      _resolvedConfig = config;
      _loadData(config: config);
    }
  }

  @override
  void didUpdateWidget(covariant EmbedDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loaderParam != widget.loaderParam ||
        oldWidget.config != widget.config ||
        oldWidget.cacheConfig != widget.cacheConfig) {
      _loadData(
        config:
            widget.config ?? _resolvedConfig ?? EmbedScope.configOf(context),
      );
    }
  }

  void _loadData({
    required EmbedConfig? config,
  }) {
    _embedFeature = EmbedService.getResult(
      param: widget.loaderParam,
      config: config,
      logger: config?.logger,
      cacheConfig: widget.cacheConfig,
      httpClient: config?.httpClient,
    ).catchError((Object error, StackTrace stackTrace) {
      // FutureBuilder will handle the error, but we catch it here to
      // prevent "Uncaught error in zone" in some test environments.
      throw error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_embedFeature == null) return const SizedBox.shrink();

    return FutureBuilder<EmbedData>(
      future: _embedFeature!,
      builder: (context, snapshot) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final didRetry = widget.controller.didRetry;
            if (snapshot.connectionState == ConnectionState.waiting) {
              final loadingWidget =
                  widget.style?.loadingBuilder?.call(context) ??
                      const Center(child: CircularProgressIndicator());
              return loadingWidget;
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              final errorWidget =
                  widget.style?.errorBuilder?.call(context, error) ??
                      const Icon(Icons.error_outline);

              if (error is EmbedDataNotFoundException ||
                  error is EmbedDataRestrictedAccessException) {
                return errorWidget;
              }

              if (!didRetry) {
                return GestureDetector(
                  onTap: () {
                    if (error is! SocketException) {
                      widget.controller.setDidRetry();
                    }
                    setState(() {
                      _loadData(
                        config: widget.config ??
                            _resolvedConfig ??
                            EmbedScope.configOf(context),
                      );
                    });
                  },
                  child: errorWidget,
                );
              }

              return errorWidget;
            }

            if (snapshot.hasData && snapshot.data != null) {
              return EmbedWebView.data(
                param: widget.param,
                data: snapshot.data!,
                maxWidth: widget.loaderParam.width,
                controller: widget.controller,
                style: widget.style,
                scrollable: widget.scrollable,
                webViewBuilder: widget.webViewBuilder,
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
