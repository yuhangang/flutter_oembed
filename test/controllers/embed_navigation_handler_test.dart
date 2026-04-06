import 'package:flutter_embed/src/controllers/embed_navigation_handler.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../fake_webview_platform.dart';

class MockNavigationRequest extends Mock implements NavigationRequest {}

void main() {
  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('EmbedNavigationHandler', () {
    late SocialEmbedParam param;
    late EmbedConfig config;

    setUp(() {
      param = SocialEmbedParam(
        url: 'https://twitter.com/user/status/123',
        embedType: EmbedType.x,
      );
      config = const EmbedConfig();
    });

    test('buildDelegate creates a NavigationDelegate', () {
      final handler = EmbedNavigationHandler(param: param, config: config);
      final delegate = handler.buildDelegate(
        loadingStateGetter: () => EmbedLoadingState.loading,
        baseUrl: 'https://twitter.com',
        onPageFinished: () async {},
      );

      expect(delegate, isA<NavigationDelegate>());
    });

    test('onNavigationRequest allows navigation during loading', () async {
      final handler = EmbedNavigationHandler(param: param, config: config);
      final delegate = handler.buildDelegate(
        loadingStateGetter: () => EmbedLoadingState.loading,
        baseUrl: 'https://twitter.com',
        onPageFinished: () async {},
      );

      final request = MockNavigationRequest();
      when(() => request.url).thenReturn('https://twitter.com/other');
      when(() => request.isMainFrame).thenReturn(true);

      final decision = await delegate.onNavigationRequest!(request);
      expect(decision, NavigationDecision.navigate);
    });

    test('onNavigationRequest prevents navigation to external URLs when loaded',
        () async {
      final handler = EmbedNavigationHandler(param: param, config: config);
      final delegate = handler.buildDelegate(
        loadingStateGetter: () => EmbedLoadingState.loaded,
        baseUrl: 'https://twitter.com',
        onPageFinished: () async {},
      );

      final request = MockNavigationRequest();
      when(() => request.url).thenReturn('https://google.com');
      when(() => request.isMainFrame).thenReturn(true);

      final decision = await delegate.onNavigationRequest!(request);
      expect(decision, NavigationDecision.prevent);
    });

    test('onNavigationRequest allows about:blank', () async {
      final handler = EmbedNavigationHandler(param: param, config: config);
      final delegate = handler.buildDelegate(
        loadingStateGetter: () => EmbedLoadingState.loaded,
        baseUrl: 'https://twitter.com',
        onPageFinished: () async {},
      );

      final request = MockNavigationRequest();
      when(() => request.url).thenReturn('about:blank');
      when(() => request.isMainFrame).thenReturn(true);

      final decision = await delegate.onNavigationRequest!(request);
      expect(decision, NavigationDecision.navigate);
    });
  });
}
