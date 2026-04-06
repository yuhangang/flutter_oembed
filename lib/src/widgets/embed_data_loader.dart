import 'dart:io';

import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/core/embed_delegate.dart';
import 'package:flutter_embed/src/services/embed_service.dart';
import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/models/embed_loader_param.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_webview.dart';
import 'package:flutter_embed/src/utils/embed_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/core/simple_embed_delegate.dart';
import 'package:flutter_embed/src/models/embed_cache_config.dart';

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
  late Future<EmbedData> _embedFeature;
  EmbedDelegate? _resolvedDelegate;
  EmbedConfig? _resolvedConfig;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = EmbedScope.delegateOf(context);
    final config = widget.config ?? EmbedScope.configOf(context);

    if (_resolvedDelegate != delegate || _resolvedConfig != config) {
      _resolvedDelegate = delegate;
      _resolvedConfig = config;
      _loadData(delegate: delegate, config: config);
    }
  }

  @override
  void didUpdateWidget(covariant EmbedDataLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loaderParam != widget.loaderParam ||
        oldWidget.config != widget.config ||
        oldWidget.cacheConfig != widget.cacheConfig) {
      _loadData(
        delegate: _resolvedDelegate ?? EmbedScope.delegateOf(context),
        config: widget.config ?? _resolvedConfig ?? EmbedScope.configOf(context),
      );
    }
  }

  void _loadData({
    required EmbedDelegate? delegate,
    required EmbedConfig? config,
  }) {
    _embedFeature = EmbedService.getResult(
      param: widget.loaderParam,
      delegate: delegate,
      config: config,
      logger: config?.logger,
      cacheConfig: widget.cacheConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmbedData>(
      future: _embedFeature,
      builder: (context, snapshot) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final didRetry = widget.controller.didRetry;
            final delegate =
                EmbedScope.delegateOf(context) ?? const SimpleEmbedDelegate();

            if (snapshot.connectionState == ConnectionState.waiting) {
              final loadingWidget =
                  widget.style?.loadingBuilder?.call(context) ??
                      delegate.buildSocialEmbedPlaceholder(
                        context: context,
                        embedType: widget.param.embedType,
                      );
              return loadingWidget;
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              if (error is EmbedDataNotFoundException ||
                  error is EmbedDataRestrictedAccessException) {
                final errorWidget =
                    widget.style?.errorBuilder?.call(context, error) ??
                        delegate.buildSocialEmbedErrorPlaceholder(
                          context: context,
                          param: widget.param,
                          error: error as Exception,
                        );
                return errorWidget;
              }

              if (!didRetry) {
                return delegate.buildSocialEmbedRefreshPlaceholder(
                  context: context,
                  param: widget.param,
                  onTap: () async {
                    final hasConnection = delegate.checkConnection();

                    if (hasConnection) {
                      if (error is! SocketException) {
                        widget.controller.setDidRetry();
                      }
                      setState(() {
                        _loadData(
                          delegate: _resolvedDelegate ??
                              EmbedScope.delegateOf(context),
                          config: widget.config ??
                              _resolvedConfig ??
                              EmbedScope.configOf(context),
                        );
                      });
                    }
                  },
                );
              }

              final errorWidget =
                  widget.style?.errorBuilder?.call(context, error) ??
                      delegate.buildSocialEmbedErrorPlaceholder(
                        context: context,
                        param: widget.param,
                      );

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
