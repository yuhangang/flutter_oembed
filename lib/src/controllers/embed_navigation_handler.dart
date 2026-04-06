import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/logging/embed_logger.dart';
import 'package:flutter_embed/src/models/embed_data.dart';

/// Encapsulates the [NavigationDelegate] creation logic, keeping
/// [EmbedController] focused on state management.
class EmbedNavigationHandler {
  final SocialEmbedParam param;
  final EmbedConfig? config;

  /// Resolved scaffold background color — captured at build time to avoid
  /// using [BuildContext] across async gaps.
  final Color? backgroundColor;

  /// Whether the embed is currently visible on screen.
  bool isVisible = true;

  /// The OEmbed data being displayed, passed to link-click callbacks for analysis.
  EmbedData? oembedData;

  EmbedNavigationHandler({
    required this.param,
    required this.config,
    this.backgroundColor,
  });

  /// Returns the [NavigationDelegate] for the WebView.
  ///
  /// [onPageFinished] is called when the page finishes loading (can be
  /// overridden per embed type). [loadingStateGetter] lets the delegate check
  /// the current loading state without a direct reference to the controller.
  NavigationDelegate buildDelegate({
    required String? baseUrl,
    required Future<void> Function() onPageFinished,
    required EmbedLoadingState Function() loadingStateGetter,
    void Function(String url)? onPageStarted,
    void Function(WebResourceError error)? onWebResourceError,
  }) {
    final logger = config?.logger ?? const EmbedLogger.disabled();
    return NavigationDelegate(
      onHttpError: (error) {
        logger.warning('WebView HTTP error', data: {
          'url': param.url,
          'errorCode': error.response?.statusCode,
        });
      },
      onPageStarted: (url) {
        logger.debug('WebView page started loading', data: {
          'url': param.url,
          'loadingUrl': url,
        });
        onPageStarted?.call(url);
      },
      onPageFinished: (url) {
        logger.debug('WebView page finished loading', data: {
          'url': param.url,
          'loadingUrl': url,
        });
        onPageFinished();
      },
      onWebResourceError: (error) {
        logger.warning('WebView resource error', data: {
          'url': param.url,
          'errorCode': error.errorCode,
          'description': error.description,
          'errorType': error.errorType?.toString(),
          'isForMainFrame': error.isForMainFrame,
        });
        onWebResourceError?.call(error);
      },
      onNavigationRequest: (request) async {
        // 1. Custom config override (full control)
        if (config?.onNavigationRequest != null) {
          final decision = await config!.onNavigationRequest!(request);
          if (decision != null) return decision;
        }

        final state = loadingStateGetter();
        if (state == EmbedLoadingState.loading) {
          logger.debug('Allowing navigation while loading', data: {
            'url': param.url,
            'targetUrl': request.url,
          });

          return NavigationDecision.navigate;
        }
        if (request.url == 'about:blank') {
          logger.debug('Allowing about:blank navigation', data: {
            'url': param.url,
          });
          return NavigationDecision.navigate;
        }

        // 3. Provider-specific internal navigation
        final provider = config?.providers.effectiveProviders.firstWhereOrNull(
          (r) => r.matches(param.url),
        );
        if (provider?.shouldAllowNavigation?.call(request.url) ?? false) {
          logger.debug(
            'Provider allowed internal navigation',
            data: {
              'url': param.url,
              'provider': provider?.providerName,
              'targetUrl': request.url,
            },
          );
          return NavigationDecision.navigate;
        }

        // 4. External link handling (only when visible)
        if (isVisible &&
            (baseUrl == null ||
                (request.url != baseUrl && request.url != '$baseUrl/'))) {
          final url =
              param.embedType == EmbedType.tiktok ? param.url : request.url;
          logger.debug('Handling external navigation', data: {
            'url': param.url,
            'targetUrl': url,
          });

          if (config?.onLinkTap != null) {
            config!.onLinkTap!(url, oembedData);
          } else {
            logger.warning('Link tap unhandled (onLinkTap not configured)',
                data: {
                  'url': param.url,
                  'targetUrl': url,
                });
          }
        }

        return NavigationDecision.prevent;
      },
    );
  }
}
