import 'package:flutter_test/flutter_test.dart';

import 'package:embed_example/utils/settings_controller.dart';

void main() {
  group('ExampleSettings', () {
    test('copyWith preserves proxyUrl when unchanged', () {
      const settings = ExampleSettings(proxyUrl: 'http://localhost:8080/');

      final result = settings.copyWith(locale: 'ms');

      expect(result.locale, 'ms');
      expect(result.proxyUrl, 'http://localhost:8080/');
    });

    test('copyWith can clear proxyUrl', () {
      const settings = ExampleSettings(proxyUrl: 'http://localhost:8080/');

      final result = settings.copyWith(proxyUrl: null);

      expect(result.proxyUrl, isNull);
    });
  });

  group('ExampleSettingsController', () {
    test('updateProxyUrl clears the active proxy', () {
      final controller = ExampleSettingsController();

      controller.updateProxyUrl('http://localhost:8080/');
      expect(controller.settings.proxyUrl, 'http://localhost:8080/');

      controller.updateProxyUrl(null);
      expect(controller.settings.proxyUrl, isNull);
    });
  });
}
