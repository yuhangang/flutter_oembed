import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_embed_service.dart';

void main() {
  test('public API exports IEmbedService for EmbedConfig.embedService', () {
    final service = FakeEmbedService();
    final config = EmbedConfig(embedService: service);
    final typedService = config.embedService;

    expect(typedService, isA<IEmbedService>());
    expect(typedService, same(service));
  });
}
