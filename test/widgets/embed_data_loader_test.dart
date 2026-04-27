import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';
import 'package:flutter_oembed/src/core/embed_scope.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/core/embed_strings.dart';
import 'package:flutter_oembed/src/models/core/embed_style.dart';
import 'package:flutter_oembed/src/models/params/social_embed_param.dart';
import 'package:flutter_oembed/src/widgets/embed_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../fake_webview_platform.dart';
import '../helpers/fake_embed_service.dart';

class MockHttpClient extends Mock implements http.Client {}

EmbedController buildController({
  SocialEmbedParam? param,
  EmbedConfig? config,
}) {
  final controller = EmbedController(config: config);
  if (param != null) {
    controller.synchronize(
      contentKey: param,
      config: config,
    );
  }
  return controller;
}

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
      controller = buildController(param: param, config: testConfig);
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
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
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

    testWidgets('uses configured strings for loading semantics',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        final completer = Completer<http.Response>();
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) => completer.future);

        final localizedConfig = testConfig.copyWith(
          strings: const EmbedStrings(
            loadingSemanticsLabel: 'Memuat kandungan benam',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedDataLoader(
                param: param,
                loaderParam: loaderParam,
                controller: controller,
                config: localizedConfig,
              ),
            ),
          ),
        );

        await tester.pump();

        expect(
          find.bySemanticsLabel('Memuat kandungan benam'),
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
      await tester.pumpAndSettle();
    });

    testWidgets('uses the configured embed service from EmbedScope',
        (tester) async {
      final service = FakeEmbedService(
        getResultResponse: const EmbedData(
          type: 'rich',
          html: '<div>Injected Service Result</div>',
        ),
      );
      final config = EmbedConfig(
        embedService: service,
        cache: const EmbedCacheConfig(enabled: false),
      );
      final scopedController = buildController(param: param, config: config);

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: EmbedScope(
              config: config,
              child: Scaffold(
                body: EmbedDataLoader(
                  param: param,
                  loaderParam: loaderParam,
                  controller: scopedController,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(service.getResultCallCount, 1);
        expect(service.lastGetResultConfig, same(config));
        expect(
          scopedController.embedData?.html,
          equals('<div>Injected Service Result</div>'),
        );
      } finally {
        scopedController.dispose();
      }
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

    testWidgets('reloads when only the http client changes', (tester) async {
      final firstClient = MockHttpClient();
      final secondClient = MockHttpClient();
      final firstCompleter = Completer<http.Response>();

      when(() => firstClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) => firstCompleter.future);
      when(() => secondClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      final config1 = EmbedConfig(
        httpClient: firstClient,
        cache: const EmbedCacheConfig(enabled: false),
      );
      final config2 = EmbedConfig(
        httpClient: secondClient,
        cache: const EmbedCacheConfig(enabled: false),
      );

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

      await tester.pump();
      verify(() => firstClient.get(any(), headers: any(named: 'headers')))
          .called(1);

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

      verify(() => secondClient.get(any(), headers: any(named: 'headers')))
          .called(1);

      firstCompleter.complete(http.Response('{}', 200));
      await tester.pumpAndSettle();
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

    testWidgets('shows error widget on API failure and retries on tap',
        (tester) async {
      int callCount = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        callCount++;
        return http.Response('Server Error', 500);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
              config: testConfig,
              style: EmbedStyle(
                errorBuilder: (context, error) =>
                    const Icon(Icons.error, key: Key('error_icon')),
              ),
            ),
          ),
        ),
      );

      // Wait for the future to complete
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Should show the error widget with retry behavior (didRetry is still false)
      expect(find.byKey(const Key('error_icon')), findsOneWidget);
      expect(controller.didRetry, isFalse);
      final firstCallCount = callCount;

      // Tap to retry
      await tester.tap(find.byKey(const Key('error_icon')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Should have re-called the API
      expect(callCount, greaterThan(firstCallCount));
      expect(controller.didRetry, isTrue);
    });

    testWidgets('404 (EmbedDataNotFoundException) shows error without retry',
        (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      // Pre-set didRetry to true to skip retry path
      controller.setDidRetry();

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

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Error widget should be present (default Icon)
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets(
        'shows not-found semantics label for EmbedDataNotFoundException',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Not Found', 404));

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

        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.bySemanticsLabel('Embedded content not found'),
          findsOneWidget,
        );
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('shows generic error semantics on non-404 failure',
        (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        when(() => mockClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Server Error', 500));

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

        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.bySemanticsLabel('Embedded content failed to load'),
          findsOneWidget,
        );
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}
