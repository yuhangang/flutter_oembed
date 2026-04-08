import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/models/embed_style.dart';
import 'package:flutter_oembed/src/widgets/embed_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    WebViewPlatform.instance = FakeWebViewPlatform();
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('EmbedDataLoader', () {
    late EmbedController controller;
    late SocialEmbedParam param;
    late EmbedLoaderParam loaderParam;
    late MockHttpClient mockClient;
    late EmbedConfig testConfig;

    setUp(() {
      mockClient = MockHttpClient();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));
      testConfig = EmbedConfig(
        httpClient: mockClient,
        cache: const EmbedCacheConfig(enabled: false),
        loadTimeout: const Duration(milliseconds: 20),
      );
      param = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        embedType: EmbedType.youtube,
      );
      controller = EmbedController(param: param, config: testConfig);
      loaderParam = EmbedLoaderParam(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        embedType: EmbedType.youtube,
        width: 640.0,
      );

      registerFallbackValue(Uri.parse('https://example.com'));
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('didChangeDependencies updates data', (tester) async {
      final completer = Completer<http.Response>();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: testConfig,
            child: Scaffold(
              body: EmbedDataLoader(
                param: param,
                loaderParam: loaderParam,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final newConfig = EmbedConfig(
        httpClient: mockClient,
        facebookAppId: 'new',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmbedScope(
            config: newConfig,
            child: Scaffold(
              body: EmbedDataLoader(
                param: param,
                loaderParam: loaderParam,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      completer.complete(http.Response('{}', 200));
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('exposes loading semantics while fetching embed data',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        final completer = Completer<http.Response>();
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedDataLoader(
                param: param,
                loaderParam: loaderParam,
                controller: controller,
                config: testConfig,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(
          find.bySemanticsLabel('Loading embedded content'),
          findsOneWidget,
        );

        completer.complete(http.Response('{}', 200));
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('didUpdateWidget updates data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
              config: testConfig,
            ),
          ),
        ),
      );

      final newLoaderParam = EmbedLoaderParam(
        url: 'https://www.youtube.com/watch?v=new',
        embedType: EmbedType.youtube,
        width: 640.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: newLoaderParam,
              controller: controller,
              config: testConfig,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('trigger build branches', (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
              config: testConfig,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('didChangeDependencies with direct config change',
        (tester) async {
      final config1 = EmbedConfig(httpClient: mockClient, facebookAppId: '1');
      final config2 = EmbedConfig(httpClient: mockClient, facebookAppId: '2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
              config: config1,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
              config: config2,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows custom loading widget', (tester) async {
      final completer = Completer<http.Response>();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
              config: testConfig,
              style: EmbedStyle(
                loadingBuilder: (context) =>
                    const Text('Custom Loading', key: Key('custom_loading')),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byKey(const Key('custom_loading')), findsOneWidget);

      completer.complete(http.Response('{}', 200));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
