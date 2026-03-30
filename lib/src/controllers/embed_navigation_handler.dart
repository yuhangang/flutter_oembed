import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:collection/collection.dart';
import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/models/oembed_config.dart';
import 'package:oembed/src/models/social_embed_param.dart';
import 'package:oembed/src/core/oembed_delegate.dart';
import 'package:oembed/src/logging/oembed_logger.dart';
import 'package:oembed/src/models/oembed_data.dart';

/// Encapsulates the [NavigationDelegate] creation logic, keeping
/// [EmbedController] focused on state management.
class EmbedNavigationHandler {
  final SocialEmbedParam param;
  final OembedConfig? config;
  final OembedDelegate? delegate;

  /// Resolved scaffold background color — captured at build time to avoid
  /// using [BuildContext] across async gaps.
  final Color? backgroundColor;

  /// Whether the embed is currently visible on screen.
  bool isVisible = true;

  /// The OEmbed data being displayed, passed to link-click callbacks for analysis.
  OembedData? oembedData;

  EmbedNavigationHandler({
    required this.param,
    required this.config,
    required this.delegate,
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
  }) {
    final logger = config?.logger ?? const OembedLogger.disabled();
    return NavigationDelegate(
      onPageFinished: (_) => onPageFinished(),
      onNavigationRequest: (request) async {
        // 1. Custom config override (full control)
        if (config?.onNavigationRequest != null) {
          final decision = await config!.onNavigationRequest!(request);
          if (decision != null) return decision;
        }

        // 2. Fundamental navigations
        final state = loadingStateGetter();
        if (state == EmbedLoadingState.loading) {
          logger.debug('Allowing navigation while loading: ${request.url}');
          return NavigationDecision.navigate;
        }
        if (request.url == 'about:blank') {
          logger.debug('Preventing about:blank navigation for ${param.url}');
          return NavigationDecision.prevent;
        }

        // 3. Provider-specific internal navigation
        final provider = config?.providers.effectiveProviders.firstWhereOrNull(
          (r) => r.matches(param.url),
        );
        if (provider?.shouldAllowNavigation?.call(request.url) ?? false) {
          logger.debug(
            'Provider "${provider?.providerName}" allowed internal navigation: ${request.url}',
          );
          return NavigationDecision.navigate;
        }

        // 4. External link handling (only when visible)
        if (isVisible &&
            (baseUrl == null ||
                (request.url != baseUrl && request.url != '$baseUrl/'))) {
          final url =
              param.embedType == EmbedType.tiktok ? param.url : request.url;
          logger.debug('Handling external navigation for ${param.url} -> $url');

          if (config?.onLinkTap != null) {
            config!.onLinkTap!(url, oembedData);
          } else {
            await delegate?.openSocialEmbedLinkClick(
              url: url,
              embedType: param.embedType.name,
              location: EmbedButtonLocation.embed_body.name,
              source: param.source,
            );
          }
        }

        return NavigationDecision.prevent;
      },
    );
  }
}
