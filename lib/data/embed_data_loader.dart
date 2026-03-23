import 'dart:io';

import 'package:oembed/application/embed_controller.dart';
import 'package:oembed/application/oembed_service.dart';
import 'package:oembed/data/oembed_data.dart';
import 'package:oembed/domain/entities/embed_loader_param.dart';
import 'package:oembed/domain/entities/social_embed_param.dart';
import 'package:oembed/presentation/embed_webview.dart';
import 'package:oembed/utils/embed_errors.dart';
import 'package:flutter/material.dart';
import 'package:oembed/oembed_scope.dart';

class EmbedDataLoader extends StatefulWidget {
  const EmbedDataLoader({
    super.key,
    required this.param,
    required this.loaderParam,
    required this.controller,
  });

  final SocialEmbedParam param;
  final EmbedLoaderParam loaderParam;
  final EmbedController controller;

  @override
  State<EmbedDataLoader> createState() => _EmbedDataLoaderState();
}

class _EmbedDataLoaderState extends State<EmbedDataLoader> {
  late Future<OembedData> _embedFeature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final delegate = OembedScope.of(context);
    _embedFeature = OembedService.getResult(
      param: widget.loaderParam,
      delegate: delegate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OembedData>(
      future: _embedFeature,
      builder: (context, snapshot) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final didRetry = widget.controller.didRetry;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return OembedScope.of(context).buildSocialEmbedPlaceholder(context: context, embedType: widget.param.embedType);
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              if (error is EmbedDataNotFoundException ||
                  error is EmbedDataRestrictedAccessException) {
                return OembedScope.of(context).buildSocialEmbedErrorPlaceholder(context: context, param: widget.param, error: error as Exception);
              }

              if (!didRetry) {
                return OembedScope.of(context).buildSocialEmbedRefreshPlaceholder(
                  context: context,
                  param: widget.param,
                  onTap: () async {
                    final delegate = OembedScope.of(context);
                    final hasConnection = delegate.checkConnection();

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

              return OembedScope.of(context).buildSocialEmbedErrorPlaceholder(context: context, param: widget.param);
            }

            if (snapshot.hasData && snapshot.data != null) {
              return EmbedWebView.data(
                param: widget.param,
                data: snapshot.data!,
                maxWidth: widget.loaderParam.width,
                controller: widget.controller,
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
