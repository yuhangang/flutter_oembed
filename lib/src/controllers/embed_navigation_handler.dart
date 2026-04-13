import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Encapsulates the [NavigationDelegate] creation logic, keeping
/// [EmbedController] focused on state management.
class EmbedNavigationHandler {
  static const Set<String> _alwaysAllowedSchemes = {
    'about',
    'blob',
    'data',
    'javascript',
  };

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
    required List<String> trustedMainFrameUrls,
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

        final requestUrl = request.url;
        final uri = Uri.tryParse(requestUrl);
        final state = loadingStateGetter();

        // 2. Always allow internal document URLs required by embed bootstrap.
        if (_isAlwaysAllowedNavigation(requestUrl, uri)) {
          logger.debug('Allowing internal document navigation', data: {
            'url': param.url,
            'targetUrl': requestUrl,
          });
          return NavigationDecision.navigate;
        }

        // 3. Sub-frame navigations are internal embed activity.
        if (!request.isMainFrame) {
          logger.debug('Allowing sub-frame navigation', data: {
            'url': param.url,
            'targetUrl': requestUrl,
          });
          return NavigationDecision.navigate;
        }

        // 4. Provider-specific internal navigation
        final provider = config?.providers.effectiveProviders.firstWhereOrNull(
          (r) => r.matches(param.url),
        );
        if (provider?.shouldAllowNavigation?.call(requestUrl) ?? false) {
          logger.debug(
            'Provider allowed internal navigation',
            data: {
              'url': param.url,
              'provider': provider?.providerName,
              'targetUrl': requestUrl,
            },
          );
          return NavigationDecision.navigate;
        }

        // 5. Allow explicitly trusted main-frame startup URLs while loading.
        if (state == EmbedLoadingState.loading) {
          if (trustedMainFrameUrls.any(
            (trustedUrl) => _urlsMatch(requestUrl, trustedUrl),
          )) {
            logger
                .debug('Allowing trusted main-frame startup navigation', data: {
              'url': param.url,
              'targetUrl': requestUrl,
            });
            return NavigationDecision.navigate;
          }

          if (_isProviderOwnedStartupNavigation(
            requestUri: uri,
            baseUrl: baseUrl,
            trustedMainFrameUrls: trustedMainFrameUrls,
          )) {
            logger.debug('Allowing provider-owned startup navigation', data: {
              'url': param.url,
              'targetUrl': requestUrl,
            });
            return NavigationDecision.navigate;
          }
        }

        // 6. Block unexpected main-frame redirects during startup.
        if (state == EmbedLoadingState.loading) {
          logger.warning(
              'Blocked unexpected main-frame navigation while loading',
              data: {
                'url': param.url,
                'targetUrl': requestUrl,
              });
          return NavigationDecision.prevent;
        }

        // 7. Ignore hidden/background navigations.
        if (!isVisible) {
          logger
              .debug('Preventing navigation while embed is not visible', data: {
            'url': param.url,
            'targetUrl': requestUrl,
          });
          return NavigationDecision.prevent;
        }

        // 8. Hand custom schemes and external main-frame links to the host app.
        if (uri == null || uri.scheme.isEmpty) {
          logger.warning('Blocked malformed navigation request', data: {
            'url': param.url,
            'targetUrl': requestUrl,
          });
          return NavigationDecision.prevent;
        }

        await _handleExternalNavigation(
          uri,
          callbackUrl: _callbackUrlFor(requestUrl),
          logger: logger,
        );

        return NavigationDecision.prevent;
      },
    );
  }

  String _callbackUrlFor(String requestUrl) {
    return param.embedType == EmbedType.tiktok ? param.url : requestUrl;
  }

  bool _isAlwaysAllowedNavigation(String requestUrl, Uri? uri) {
    if (requestUrl == 'about:blank') {
      return true;
    }

    final scheme = uri?.scheme.toLowerCase();
    return scheme != null && _alwaysAllowedSchemes.contains(scheme);
  }

  bool _urlsMatch(String first, String second) {
    return _trimTrailingSlash(first) == _trimTrailingSlash(second);
  }

  String _trimTrailingSlash(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  bool _isProviderOwnedStartupNavigation({
    required Uri? requestUri,
    required String? baseUrl,
    required List<String> trustedMainFrameUrls,
  }) {
    final requestHost = requestUri?.host.toLowerCase();
    if (requestHost == null || requestHost.isEmpty) {
      return false;
    }

    final trustedHosts = <String>{
      ..._collectHosts(trustedMainFrameUrls),
      ..._collectHosts([param.url]),
      ..._collectHosts([if (baseUrl != null) baseUrl]),
    };

    return trustedHosts.any((host) => _hostMatches(requestHost, host));
  }

  Set<String> _collectHosts(List<String> urls) {
    return urls
        .map(Uri.tryParse)
        .map((uri) => uri?.host.toLowerCase())
        .whereType<String>()
        .where((host) => host.isNotEmpty)
        .toSet();
  }

  bool _hostMatches(String requestHost, String trustedHost) {
    return requestHost == trustedHost ||
        requestHost.endsWith('.$trustedHost') ||
        trustedHost.endsWith('.$requestHost') ||
        _baseDomain(requestHost) == _baseDomain(trustedHost);
  }

  String _baseDomain(String host) {
    final parts = host.split('.');
    if (parts.length < 2) {
      return host;
    }
    return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
  }

  Future<void> _handleExternalNavigation(
    Uri uri, {
    required String callbackUrl,
    required EmbedLogger logger,
  }) async {
    final scheme = uri.scheme.toLowerCase();
    final targetUrl = uri.toString();

    logger.debug('Handling external navigation', data: {
      'url': param.url,
      'targetUrl': targetUrl,
      'scheme': scheme,
    });

    if (config?.onLinkTap != null) {
      config!.onLinkTap!(callbackUrl, oembedData);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        logger.warning('External navigation could not be launched', data: {
          'url': param.url,
          'targetUrl': targetUrl,
        });
      }
    } catch (error, stackTrace) {
      logger.warning(
        'External navigation launch failed',
        data: {
          'url': param.url,
          'targetUrl': targetUrl,
        },
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
