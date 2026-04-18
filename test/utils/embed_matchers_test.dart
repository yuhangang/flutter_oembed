import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/utils/embed_matchers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_embed_service.dart';

void main() {
  group('EmbedMatchers', () {
    group('getEmbedType()', () {
      test('should return EmbedType.youtube when a YouTube URL is provided',
          () {
        expect(EmbedMatchers.getEmbedType('https://youtube.com/watch?v=123'),
            equals(EmbedType.youtube));
        expect(EmbedMatchers.getEmbedType('https://youtu.be/123'),
            equals(EmbedType.youtube));
      });

      test('should return EmbedType.tiktok when a TikTok URL is provided', () {
        expect(EmbedMatchers.getEmbedType('https://tiktok.com/@u/video/1'),
            equals(EmbedType.tiktok));
        expect(EmbedMatchers.getEmbedType('https://www.tiktok.com/@scout2015'),
            equals(EmbedType.tiktok));
      });

      test('should return EmbedType.x when a Twitter or X URL is provided', () {
        expect(EmbedMatchers.getEmbedType('https://twitter.com/u/status/1'),
            equals(EmbedType.x));
        expect(EmbedMatchers.getEmbedType('https://x.com/u/status/1'),
            equals(EmbedType.x));
      });

      test('should return EmbedType.reddit when a Reddit URL is provided', () {
        expect(EmbedMatchers.getEmbedType('https://reddit.com/r/u/comments/1'),
            equals(EmbedType.reddit));
      });

      test(
          'should return EmbedType.instagram when an Instagram URL is provided',
          () {
        expect(EmbedMatchers.getEmbedType('https://instagram.com/p/1'),
            equals(EmbedType.instagram));
      });

      test('should return EmbedType.facebook when a Facebook URL is provided',
          () {
        expect(EmbedMatchers.getEmbedType('https://facebook.com/post/1'),
            equals(EmbedType.facebook));
      });

      test('should return EmbedType.threads when a Threads URL is provided',
          () {
        expect(EmbedMatchers.getEmbedType('https://threads.net/@u/post/1'),
            equals(EmbedType.threads));
      });

      test(
          'should return EmbedType.soundcloud when a SoundCloud URL is provided',
          () {
        expect(EmbedMatchers.getEmbedType('https://soundcloud.com/u/p'),
            equals(EmbedType.soundcloud));
      });

      test('should return EmbedType.spotify when a Spotify URL is provided',
          () {
        expect(EmbedMatchers.getEmbedType('https://open.spotify.com/track/1'),
            equals(EmbedType.spotify));
      });

      test('should return EmbedType.other when an unknown URL is provided', () {
        expect(EmbedMatchers.getEmbedType('https://unknown.com'),
            equals(EmbedType.other));
      });

      test('should use the configured embed service when provided', () {
        final service = FakeEmbedService(
          resolveRuleResponse: const EmbedProviderRule(
            pattern: r'https?://unknown\.com/.*',
            endpoint: 'https://example.com/oembed',
            providerName: 'Spotify',
          ),
        );

        expect(
          EmbedMatchers.getEmbedType(
            'https://unknown.com/post/123',
            config: EmbedConfig(embedService: service),
          ),
          equals(EmbedType.spotify),
        );
        expect(service.resolveRuleCallCount, 1);
      });
    });

    group('fromProviderName()', () {
      test('should return the correct EmbedType for various provider names',
          () {
        expect(EmbedMatchers.fromProviderName('Twitter'), equals(EmbedType.x));
        expect(EmbedMatchers.fromProviderName('Instagram'),
            equals(EmbedType.instagram));
        expect(EmbedMatchers.fromProviderName('Spotify'),
            equals(EmbedType.spotify));
        expect(
            EmbedMatchers.fromProviderName('Vimeo'), equals(EmbedType.vimeo));
        expect(EmbedMatchers.fromProviderName('Dailymotion'),
            equals(EmbedType.dailymotion));
        expect(EmbedMatchers.fromProviderName('SoundCloud'),
            equals(EmbedType.soundcloud));
        expect(EmbedMatchers.fromProviderName('Threads'),
            equals(EmbedType.threads));
        expect(
            EmbedMatchers.fromProviderName('Reddit'), equals(EmbedType.reddit));
        expect(
            EmbedMatchers.fromProviderName('Giphy'), equals(EmbedType.giphy));
        expect(
            EmbedMatchers.fromProviderName('Unknown'), equals(EmbedType.other));
      });

      test('should handle Facebook sub-types based on URL content', () {
        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.com/videos/1'),
            equals(EmbedType.facebook_video));
        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.com/video.php?id=1'),
            equals(EmbedType.facebook_video));
        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.watch/1'),
            equals(EmbedType.facebook_video));

        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.com/posts/1'),
            equals(EmbedType.facebook_post));
        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.com/permalink.php?id=1'),
            equals(EmbedType.facebook_post));
        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.com/photo.php?id=1'),
            equals(EmbedType.facebook_post));

        expect(
            EmbedMatchers.fromProviderName('Facebook',
                url: 'https://fb.com/other'),
            equals(EmbedType.facebook));
        expect(EmbedMatchers.fromProviderName('Facebook'),
            equals(EmbedType.facebook));
      });
    });
  });
}
