import 'package:flutter_embed/src/models/embed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbedData', () {
    const json = {
      'html': '<iframe src="test"></iframe>',
      'url': 'https://example.com',
      'title': 'Test Title',
      'author_name': 'Author',
      'provider_name': 'Provider',
      'type': 'video',
      'width': 640,
      'height': 480,
      'cache_age': 3600,
    };

    test('fromJson should parse correctly', () {
      final data = EmbedData.fromJson(json);
      expect(data.html, equals('<iframe src="test"></iframe>'));
      expect(data.url, equals('https://example.com'));
      expect(data.title, equals('Test Title'));
      expect(data.authorName, equals('Author'));
      expect(data.providerName, equals('Provider'));
      expect(data.type, equals('video'));
      expect(data.width, equals(640.0));
      expect(data.height, equals(480.0));
      expect(data.cacheAge, equals(3600.0));
    });

    test('toJson should match input json', () {
      final data = EmbedData.fromJson(json);
      final outputJson = data.toJson();
      expect(outputJson['html'], equals(json['html']));
      expect(outputJson['url'], equals(json['url']));
      expect(outputJson['title'], equals(json['title']));
      expect(outputJson['author_name'], equals(json['author_name']));
      expect(outputJson['provider_name'], equals(json['provider_name']));
      expect(outputJson['type'], equals(json['type']));
      expect(outputJson['width'], equals(640.0));
      expect(outputJson['height'], equals(480.0));
      expect(outputJson['cache_age'], equals(3600.0));
    });

    test('aspectRatio should calculate correctly', () {
      final data = EmbedData.fromJson(json);
      expect(data.aspectRatio, equals(640 / 480));
    });

    test('aspectRatio should be null if width or height is missing', () {
      const data = EmbedData(html: 'test', width: 640);
      expect(data.aspectRatio, isNull);
    });

    test('cacheAgeDuration should calculate correctly', () {
      final data = EmbedData.fromJson(json);
      expect(data.cacheAgeDuration, equals(const Duration(hours: 1)));
    });

    test('photo type should have fallback HTML if missing', () {
      const photoJson = {
        'type': 'photo',
        'url': 'https://example.com/image.jpg',
      };
      final data = EmbedData.fromJson(photoJson);
      expect(data.html, contains('<img src="https://example.com/image.jpg"'));
    });

    test('copyWith should work correctly', () {
      final data = EmbedData.fromJson(json);
      final updated = data.copyWith(title: 'New Title');
      expect(updated.title, equals('New Title'));
      expect(updated.html, equals(data.html));
    });

    test('equality should work via Equatable', () {
      final data1 = EmbedData.fromJson(json);
      final data2 = EmbedData.fromJson(json);
      expect(data1, equals(data2));

      final data3 = data1.copyWith(title: 'Different');
      expect(data1, isNot(equals(data3)));
    });
  });
}
