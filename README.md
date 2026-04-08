# flutter_oembed

A Flutter package for embedding rich social and media content with oEmbed APIs and WebView rendering.

## Current Package Status

- Current package version: `1.0.0-beta`
- Verified platforms: Android, iOS
- Not supported currently: Flutter Web
- Not yet verified for release: macOS, Windows, Linux

If you are consuming the package before the stable release lands, use the current beta line:

```yaml
dependencies:
  flutter_oembed: ^1.0.0-beta
```

Update this version to `^1.0.0` once the stable release is published.

## Features

- Multiple built-in providers: X, TikTok, Instagram, Facebook, Threads, Reddit, YouTube, Vimeo, Dailymotion, Spotify, SoundCloud
- Automatic height adjustment for embedded content
- Built-in response caching
- Direct iframe rendering for selected providers such as YouTube and Spotify
- Per-provider render configuration and custom provider rules
- Debug logging hooks for provider resolution, network requests, and WebView lifecycle

## Platform Support

`flutter_oembed` currently targets mobile Flutter apps that can host a platform WebView.

| Platform | Status | Notes |
| :--- | :--- | :--- |
| Android | Supported | Verified in the current repo workflow |
| iOS | Supported | Verified in the current repo workflow |
| Flutter Web | Not supported | This package relies on `webview_flutter`; there is no iframe-based web fallback yet |
| macOS | Unverified | Not part of the current release verification matrix |
| Windows | Unverified | Not part of the current release verification matrix |
| Linux | Unverified | Not part of the current release verification matrix |

## Provider Notes

- Meta providers such as Facebook, Instagram, and Threads require a Meta App ID and Client Token.
- Provider behavior is not uniform. Some providers expose less metadata or more restrictive embed behavior than others.
- Dark mode support varies by provider. `brightness` is not guaranteed to affect every provider embed.
- The package auto-pauses media when embeds leave the viewport, but there is no stable public media-control API yet.

## Supported Providers

`flutter_oembed` ships with verified support for these provider groups:

| Category | Providers |
| :--- | :--- |
| Social | X, Facebook, Instagram, Threads, Reddit, TikTok |
| Video | YouTube, Vimeo, Dailymotion |
| Audio | Spotify, SoundCloud |

## Getting Started

Wrap your app in an `EmbedScope` to provide global configuration:

```dart
EmbedScope(
  config: EmbedConfig(
    facebookAppId: 'YOUR_APP_ID',
    facebookClientToken: 'YOUR_CLIENT_TOKEN',
  ),
  child: MyApp(),
)
```

Then render content with `EmbedCard`:

```dart
EmbedCard(
  url: 'https://twitter.com/X/status/1328842765115920384',
  embedType: EmbedType.x,
  onLinkTap: (url, data) {
    debugPrint('User tapped link: $url');
  },
)
```

## Meta Setup

Facebook, Instagram, and Threads embeds require credentials from [Meta for Developers](https://developers.facebook.com/).

References:
- [Meta oEmbed Documentation](https://developers.facebook.com/docs/graph-api/reference/v22.0/oembed-read/)
- [Facebook oEmbed API Guide](https://developers.facebook.com/docs/plugins/oembed)
- [Instagram oEmbed API Guide](https://developers.facebook.com/docs/instagram/oembed)
- [Threads oEmbed API Guide](https://developers.facebook.com/docs/threads/tools-and-resources/embed-a-threads-post)

## Advanced Configuration

You can customize caching, provider render modes, and style:

```dart
EmbedConfig(
  providers: EmbedProviderConfig(
    providerRenderModes: {
      'YouTube': EmbedRenderMode.iframe,
      'Spotify': EmbedRenderMode.iframe,
    },
  ),
  cache: EmbedCacheConfig(
    enabled: true,
    defaultCacheDuration: Duration(days: 7),
  ),
  style: EmbedStyle(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

## Debug Logging

Enable debug logging when you need visibility into provider resolution, cache hits, network requests, and WebView loading events:

```dart
EmbedConfig(
  logger: const EmbedLogger.debug(),
)
```

You can also forward logs to your own logger:

```dart
EmbedConfig(
  onLinkTap: (url, data) {
    debugPrint('Clicked $url on $data');
  },
  logger: EmbedLogger.enabled(
    level: EmbedLogLevel.info,
    sink: ({
      required EmbedLogLevel level,
      required String message,
      Object? error,
      StackTrace? stackTrace,
    }) {
      myLogger.log(
        message,
        level: level.name,
        error: error,
        stackTrace: stackTrace,
      );
    },
  ),
)
```

## HTML And Markdown Integration

The repository example app includes working integrations for:

- `markdown_widget`
- `flutter_html`
- Quill-based editors

See the example app in `/example` for concrete integration code.

## Troubleshooting

- If Meta embeds fail, verify your App ID and Client Token first.
- If a provider resolves but renders an empty frame, enable debug logging and inspect WebView/network events.
- If a URL is not matched, provide a custom provider rule or enable dynamic discovery where appropriate.
- If you need Flutter Web support, this package does not provide it yet.

## Additional Information

- Example app: `/example`
- Release checklist: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
