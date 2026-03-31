import 'dart:io';

import 'package:flutter_embed/src/controllers/embed_controller.dart';
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

class EmbedDataLoader extends StatefulWidget {
  final SocialEmbedParam param;
  final EmbedLoaderParam loaderParam;
  final EmbedController controller;
  final EmbedConfig? config;
  final EmbedStyle? style;
  final bool scrollable;

  const EmbedDataLoader({
    super.key,
    required this.param,
    required this.loaderParam,
    required this.controller,
    this.config,
    this.style,
    this.scrollable = false,
  });

  @override
  State<EmbedDataLoader> createState() => _EmbedDataLoaderState();
}

class _EmbedDataLoaderState extends State<EmbedDataLoader> {
  late Future<EmbedData> _embedFeature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final delegate = EmbedScope.delegateOf(context);
    final config = widget.config ?? EmbedScope.configOf(context);
    _embedFeature = EmbedService.getResult(
      param: widget.loaderParam,
      delegate: delegate,
      config: config,
      logger: config?.logger,
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

            if (snapshot.connectionState == ConnectionState.waiting) {
              final loadingWidget =
                  widget.style?.loadingBuilder?.call(context) ??
                  EmbedScope.delegateOf(context)?.buildSocialEmbedPlaceholder(
                    context: context,
                    embedType: widget.param.embedType,
                  );
              return loadingWidget ??
                  const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              if (error is EmbedDataNotFoundException ||
                  error is EmbedDataRestrictedAccessException) {
                final errorWidget =
                    widget.style?.errorBuilder?.call(context, error) ??
                    EmbedScope.delegateOf(
                      context,
                    )?.buildSocialEmbedErrorPlaceholder(
                      context: context,
                      param: widget.param,
                      error: error as Exception,
                    );
                return errorWidget ?? const Icon(Icons.error_outline);
              }

              if (!didRetry) {
                return EmbedScope.of(
                  context,
                ).buildSocialEmbedRefreshPlaceholder(
                  context: context,
                  param: widget.param,
                  onTap: () async {
                    final delegate = EmbedScope.delegateOf(context);
                    final hasConnection = delegate?.checkConnection() ?? true;

                    if (hasConnection) {
                      if (error is! SocketException) {
                        widget.controller.setDidRetry();
                      }
                      setState(() {
                        _loadData();
                      });
                    }
                  },
                );
              }

              final errorWidget =
                  widget.style?.errorBuilder?.call(context, error) ??
                  EmbedScope.delegateOf(
                    context,
                  )?.buildSocialEmbedErrorPlaceholder(
                    context: context,
                    param: widget.param,
                  );

              return errorWidget ?? const Icon(Icons.error_outline);
            }

            if (snapshot.hasData && snapshot.data != null) {
              return EmbedWebView.data(
                param: widget.param,
                data: snapshot.data!,
                maxWidth: widget.loaderParam.width,
                controller: widget.controller,
                scrollable: widget.scrollable,
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
