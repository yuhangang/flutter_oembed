import 'package:flutter_oembed/src/utils/embed_webview_controller_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MockWebViewController extends Mock implements WebViewController {}

class FakeWebKitWebViewPlatform extends Fake implements WebKitWebViewPlatform {}

void main() {
  group('EmbedWebviewControllerUtils', () {
    test('muteAudioWidget and pauseVideos', () async {
      final controller = MockWebViewController();
      when(() => controller.runJavaScript(any())).thenAnswer((_) async {});

      await controller.muteAudioWidget();
      verify(() => controller.runJavaScript(any())).called(1);

      await controller.pauseVideos();
      verify(() => controller.runJavaScript(any())).called(1);
    });
  });
}
