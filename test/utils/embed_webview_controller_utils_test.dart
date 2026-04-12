import 'package:flutter_oembed/src/utils/embed_webview_controller_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MockWebViewController extends Mock implements WebViewController {}

void main() {
  group('EmbedWebviewControllerUtils', () {
    test(
        'media element helpers run JavaScript for mute, pause, resume, unmute, and seek',
        () async {
      final controller = MockWebViewController();
      when(() => controller.runJavaScript(any())).thenAnswer((_) async {});

      await controller.muteMediaElements();
      verify(() => controller.runJavaScript(any())).called(1);

      await controller.pauseMediaElements();
      verify(() => controller.runJavaScript(any())).called(1);

      await controller.resumeMediaElements();
      verify(() => controller.runJavaScript(any())).called(1);

      await controller.unmuteMediaElements();
      verify(() => controller.runJavaScript(any())).called(1);

      await controller.seekMediaElementsTo(42);
      verify(() => controller.runJavaScript(any())).called(1);
    });

    test('postJsonStringMessageToIframes targets matching players only',
        () async {
      final controller = MockWebViewController();
      final scripts = <String>[];
      when(() => controller.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });

      await controller.postJsonStringMessageToIframes(
        srcFragments: const ['youtube-nocookie.com', 'youtube.com'],
        messageJson: '{"event":"command","func":"pauseVideo","args":""}',
      );

      expect(scripts, hasLength(1));
      expect(scripts.single, contains('youtube-nocookie.com'));
      expect(scripts.single, contains('youtube.com'));
      expect(scripts.single, contains('window.location'));
      expect(scripts.single, contains('window.postMessage'));
      expect(scripts.single, contains('pauseVideo'));
    });

    test('postJavaScriptMessageToIframes keeps object payloads intact',
        () async {
      final controller = MockWebViewController();
      final scripts = <String>[];
      when(() => controller.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });

      await controller.postJavaScriptMessageToIframes(
        srcFragments: const ['tiktok.com/player/'],
        messageExpression:
            '{"type":"seekTo","value":42,"x-tiktok-player":true}',
      );

      expect(scripts, hasLength(1));
      expect(scripts.single, contains('tiktok.com/player/'));
      expect(scripts.single, contains('"type":"seekTo"'));
      expect(scripts.single, contains('"value":42'));
      expect(scripts.single, contains('"x-tiktok-player":true'));
    });

    test('postJsonStringMessageToIframes can target a top-level player page',
        () async {
      final controller = MockWebViewController();
      final scripts = <String>[];
      when(() => controller.runJavaScript(any()))
          .thenAnswer((invocation) async {
        scripts.add(invocation.positionalArguments.first as String);
      });

      await controller.postJsonStringMessageToIframes(
        srcFragments: const ['vimeo.com'],
        messageJson: '{"method":"pause"}',
      );

      expect(scripts, hasLength(1));
      expect(scripts.single, contains("currentHref.indexOf(fragments[i])"));
      expect(scripts.single,
          contains("window.postMessage('{\"method\":\"pause\"}', '*')"));
    });
  });
}
