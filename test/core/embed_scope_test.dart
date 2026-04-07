import 'package:flutter/material.dart';
import 'package:flutter_embed/src/core/embed_scope.dart';
import 'package:flutter_embed/src/models/embed_config.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedScope', () {
    testWidgets('configOf and styleOf', (tester) async {
      const config = EmbedConfig(style: EmbedStyle(maxScrollableHeight: 500));
      
      late EmbedConfig? capturedConfig;
      late EmbedStyle? capturedStyle;

      await tester.pumpWidget(
        EmbedScope(
          config: config,
          child: Builder(
            builder: (context) {
              capturedConfig = EmbedScope.configOf(context, listen: false);
              capturedStyle = EmbedScope.styleOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedConfig, equals(config));
      expect(capturedStyle, equals(config.style));
    });

    test('updateShouldNotify', () {
      const config1 = EmbedConfig(facebookAppId: '1');
      const config2 = EmbedConfig(facebookAppId: '2');
      
      const scope1 = EmbedScope(config: config1, child: SizedBox());
      const scope2 = EmbedScope(config: config1, child: SizedBox());
      const scope3 = EmbedScope(config: config2, child: SizedBox());

      expect(scope1.updateShouldNotify(scope2), isFalse);
      expect(scope1.updateShouldNotify(scope3), isTrue);
    });

    /*
    test('clearCache does not crash', () async {
      // We can't easily verify the actual filesystem clear in a unit test without mocking DefaultCacheManager
      // but we can ensure it doesn't crash.
      await EmbedScope.clearCache();
    });
    */
  });
}
