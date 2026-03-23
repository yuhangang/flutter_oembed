import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:oembed/domain/entities/social_embed_param.dart';
import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:oembed/oembed_delegate.dart';
import 'package:oembed/data/oembed_data.dart';
import 'package:oembed/utils/embed_html_utils.dart';
import 'package:oembed/utils/embed_webview_controller_utils.dart';
import 'package:oembed/utils/embed_link_utils.dart';

class EmbedController extends ChangeNotifier {
  final SocialEmbedParam param;
  final OembedDelegate delegate;

  EmbedLoadingState loadingState = EmbedLoadingState.loading;
  bool didRetry = false;
  double? height;
  bool isVisible = true;

  late final WebViewController webViewController;

  EmbedController({
    required this.param,
    required this.delegate,
  }) {
    webViewController = generateWebViewController();
  }

  @override
  void dispose() {
    webViewController.loadRequest(Uri.parse('about:blank'));
    webViewController.setNavigationDelegate(NavigationDelegate());
    super.dispose();
  }

  void setHeight(double newHeight) {
    if (height != newHeight) {
      height = newHeight;
      notifyListeners();
    }
  }

  void updateVisibility(bool visible, {required void Function(bool) onVisibilityChange}) {
    if (isVisible != visible) {
      isVisible = visible;
      notifyListeners();
      onVisibilityChange(visible);
    }
  }

  void setLoadingState(EmbedLoadingState state) {
    if (loadingState != state) {
      loadingState = state;
      notifyListeners();
    }
  }

  void setDidRetry() {
    if (!didRetry) {
      didRetry = true;
      notifyListeners();
    }
  }

  Future<void> initEmbedWebview(
    BuildContext context, {
    required OembedData? embedData,
    required String? embedUrl,
    required double maxWidth,
  }) async {
    if (loadingState == EmbedLoadingState.loaded &&
        (height != null || param.embedType == EmbedType.tiktok)) {
      return;
    }

    await _initWebViewController(context, embedData);
    _setLoadEmbedPostTimeoutFunction();
    await _loadEmbedWebview(embedData, maxWidth, embedUrl);
  }

  Future<void> _initWebViewController(BuildContext context, OembedData? embedData) async {
    if (param.embedType == EmbedType.x) {
      await _initWebViewControllerImpl(
        context,
        embedType: EmbedType.x,
        postUrl: param.url,
        baseUrl: embedData?.providerUrl,
        javaScriptChannels: {
          'OnTwitterLoaded': (_) async => _handleOembedPageFinished(),
        },
        onWebViewLoadedOverride: () async {
          await webViewController.runJavaScript("""
            twttr.events.bind(
              'loaded',
              function (event) {
                 OnTwitterLoaded.postMessage("loaded");
              }
            );
          """);
        },
      );
    } else if (param.embedType == EmbedType.tiktok) {
      await _initWebViewControllerImpl(
        context,
        embedType: param.embedType,
        baseUrl: embedData?.providerUrl,
        postUrl: param.url,
        onWebViewLoadedOverride: () async {
          setLoadingState(EmbedLoadingState.loaded);
          if (param.isTikTokPhoto) {
            await webViewController.muteAudioWidget();
          }
        },
      );
    } else {
      await _initWebViewControllerImpl(
        context,
        embedType: param.embedType,
        postUrl: param.url,
        baseUrl: embedData?.providerUrl,
      );
    }
  }

  Future<void> _initWebViewControllerImpl(
    BuildContext context, {
    required EmbedType embedType,
    required String postUrl,
    required String? baseUrl,
    Map<String, void Function(JavaScriptMessage)>? javaScriptChannels,
    VoidCallback? onWebViewLoadedOverride,
  }) async {
    webViewController.setBackgroundColor(delegate.scaffoldBackgroundColor(context));
    webViewController.enableZoom(false);
    webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

    if (javaScriptChannels != null) {
      for (final element in javaScriptChannels.entries) {
        webViewController.addJavaScriptChannel(
          element.key,
          onMessageReceived: element.value,
        );
      }
    }

    await webViewController.setNavigationDelegate(
      getNavigtionDelegate(
        context,
        postUrl,
        onWebViewLoadedOverride: onWebViewLoadedOverride,
        baseUrl: baseUrl,
      ),
    );
  }

  Future<void> _loadEmbedWebview(OembedData? embedData, double maxWidth, String? embedUrl) async {
    if (embedData != null) {
      await webViewController.loadHtmlString(
        loadEmbedHtmlDocument(
          embedData.html,
          type: param.embedType,
          contentType: param.embedContentType,
          maxWidth: maxWidth,
        ),
        baseUrl: param.embedType.isFacebook ? embedData.providerUrl : null,
      );
    } else if (embedUrl != null) {
      await webViewController.loadRequest(Uri.parse(embedUrl));
    }
  }

  Future<void> _handleOembedPageFinished() async {
    await Future.delayed(const Duration(milliseconds: 1000), () async {
      if (loadingState != EmbedLoadingState.loaded) {
        await updateEmbedPostHeight();
        await Future.delayed(const Duration(milliseconds: 100));
        setLoadingState(EmbedLoadingState.loaded);

        await Future.delayed(
          param.embedType.isFacebook
              ? const Duration(milliseconds: 3000)
              : const Duration(milliseconds: 1000),
        );
        await updateEmbedPostHeight();
      }
    });
  }

  NavigationDelegate getNavigtionDelegate(
    BuildContext context,
    String postUrl, {
    VoidCallback? onWebViewLoadedOverride,
    required String? baseUrl,
  }) {
    return NavigationDelegate(
      onPageFinished: (url) async {
        if (onWebViewLoadedOverride != null) {
          onWebViewLoadedOverride.call();
        } else {
          await _handleOembedPageFinished();
        }
      },
      onNavigationRequest: (request) async {
        if (loadingState == EmbedLoadingState.loading) {
          return NavigationDecision.navigate;
        } else if (request.url == 'about:blank') {
          return NavigationDecision.prevent;
        }

        if (param.embedType.isFacebook) {
          final url = Uri.parse(request.url);
          if (url.pathSegments.contains('plugins')) {
            return NavigationDecision.navigate;
          }
        } else if (param.embedType == EmbedType.tiktok) {
          if (request.url.contains(kTikTokV3EmbedUrl)) {
            return NavigationDecision.navigate;
          }
        }

        if (isVisible &&
            (baseUrl == null || (request.url != baseUrl && request.url != '$baseUrl/'))) {
          final url = param.embedType == EmbedType.tiktok ? postUrl : request.url;
          await delegate.openSocialEmbedLinkClick(
            url: url,
            embedType: param.embedType.name,
            location: EmbedButtonLocation.embed_body.name,
            source: param.source,
          );
        }

        return NavigationDecision.prevent;
      },
    );
  }

  Future<void> updateEmbedPostHeight() async {
    try {
      final double? newHeight = await webViewController.getEmbedDocumentHeight();
      if (newHeight != null && height != newHeight) {
        setHeight(newHeight);
      }
    } catch (e) {
      return;
    }
  }

  Future<void> pauseMedias() async {
    if (param.isTikTokPhoto) {
      await webViewController.muteAudioWidget();
    } else {
      await webViewController.pauseVideos();
    }
  }

  Future<void> refresh() async {
    await webViewController.reload();
    _setLoadEmbedPostTimeoutFunction();
  }

  void _setLoadEmbedPostTimeoutFunction() {
    Future.delayed(const Duration(seconds: 10), () async {
      if (loadingState != EmbedLoadingState.loaded) {
        setLoadingState(EmbedLoadingState.error);
      }
    });
  }
}
