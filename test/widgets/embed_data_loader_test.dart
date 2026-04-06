import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_embed/src/controllers/embed_controller.dart';
import 'package:flutter_embed/src/models/embed_cache_config.dart';
import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/embed_loader_param.dart';
import 'package:flutter_embed/src/models/social_embed_param.dart';
import 'package:flutter_embed/src/widgets/embed_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MockEmbedController extends Mock implements EmbedController {}

class MockHttpClient extends Mock implements HttpClient {
  @override
  set autoUncompress(bool _autoUncompress) {}
}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('EmbedDataLoader', () {
    late EmbedController controller;
    late SocialEmbedParam param;
    late EmbedLoaderParam loaderParam;

    setUp(() {
      param = SocialEmbedParam(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        embedType: EmbedType.youtube,
      );
      controller = EmbedController(param: param);
      loaderParam = EmbedLoaderParam(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        embedType: EmbedType.youtube,
        width: 640.0,
      );
      
      // Register fallbacks
      registerFallbackValue(const SizedBox());
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmbedDataLoader(
              param: param,
              loaderParam: loaderParam,
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error icon on failure', (tester) async {
      final mockClient = MockHttpClient();
      final mockRequest = MockHttpClientRequest();
      final mockResponse = MockHttpClientResponse();
      final mockHeaders = MockHttpHeaders();

      when(() => mockClient.openUrl(any(), any())).thenAnswer((_) async => mockRequest);
      when(() => mockRequest.headers).thenReturn(mockHeaders);
      when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
      when(() => mockResponse.statusCode).thenReturn(404);
      when(() => mockResponse.reasonPhrase).thenReturn('Not Found');
      when(() => mockResponse.listen(
            any(),
            onError: any(named: 'onError'),
            onDone: any(named: 'onDone'),
            cancelOnError: any(named: 'cancelOnError'),
          )).thenAnswer((invocation) {
        final onData = invocation.positionalArguments[0] as void Function(List<int>);
        final onDone = invocation.namedArguments[#onDone] as void Function()?;
        onData(utf8.encode('{}'));
        onDone?.call();
        return MockStreamSubscription<List<int>>();
      });

      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbedDataLoader(
                param: SocialEmbedParam(url: 'https://invalid.com', embedType: EmbedType.other),
                loaderParam: EmbedLoaderParam(
                  url: 'https://invalid.com',
                  embedType: EmbedType.other,
                  width: 640.0,
                ),
                controller: controller,
                cacheConfig: const EmbedCacheConfig(enabled: false), // Disable cache to speed up and stabilize test
              ),
            ),
          ),
        );

        // First frame builds initial state (CircularProgressIndicator)
        await tester.pump(); 
        
        // Wait for the future to finish and trigger rebuild
        // Since CircularProgressIndicator is an infinite animation, 
        // pumpAndSettle would timeout. We use a long pump instead.
        await tester.pump(const Duration(seconds: 1)); 
        await tester.pump(); // Final rebuild frame

        // Check for the icon
        expect(find.byType(Icon), findsWidgets);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      }, createHttpClient: (_) => mockClient);
    });
  });
}

class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {
  @override
  Future<void> cancel() => Future.value();
}
