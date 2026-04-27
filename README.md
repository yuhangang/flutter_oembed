# flutter_oembed


[![pub package](https://img.shields.io/pub/v/flutter_oembed.svg)](https://pub.dev/packages/flutter_oembed)

A Flutter package for embedding rich social and media content with oEmbed APIs and WebView rendering.

<img width="461" height="653" alt="Screenshot 2026-04-27 at 3 08 30 PM" src="https://github.com/user-attachments/assets/685185f2-a503-4f22-b53b-906ba18a335e" />

This library is still in development. The API might change in future updates.

Contributions are welcome! Please feel free to raise issues for any bugs you encounter, or submit pull requests with ideas, suggestions, and code improvements.   

## Current Package Status

- Current package version: `1.0.1-beta.2`
- Verified platforms: Android, iOS
- Not supported currently: Flutter Web
- Not yet verified for release: macOS, Windows, Linux

Use the current stable line:

```yaml
dependencies:
  flutter_oembed: ^1.0.1-beta.2
```

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
- The package auto-pauses media when embeds leave the viewport.
- Route-cover pausing is also available for page pushes and modal bottom sheets when you provide a `RouteObserver` through `EmbedConfig.routeObserver` and `MaterialApp.navigatorObservers`.
- When the covered route becomes visible again, the package also makes a best-effort resume attempt for providers that expose controllable players. Autoplay policies may still block resume until the user interacts again.
- When multiple embeds are visible in the same route, the package treats the highest-visibility embed as focused and attempts to keep non-focused embeds paused.
- Provider media-control support is not uniform. YouTube, Vimeo, and TikTok's `player/v1` path are the most reliable. Meta-style embeds may still be best-effort only.
- `EmbedController` exposes best-effort `pauseMedia()`, `resumeMedia()`, `muteMedia()`, and `unmuteMedia()` methods once an embed is attached. TikTok `player/v1` is the most complete implementation of that API in the current package.
- To drive those controls from your own UI, pass the same `EmbedController` into `EmbedCard(controller: ...)`, `YoutubeEmbedPlayer`, or `TikTokEmbedPlayer` so the rendered embed can bind to it.

### Brightness Support Matrix

`EmbedConfig.brightness` is not a universal dark-mode switch. It is only forwarded where the upstream provider or native player path exposes a stable theme setting.

| Provider path | `brightness` support | Notes |
| :--- | :--- | :--- |
| X | Supported | Mapped to the `theme` query parameter |
| Reddit | Supported | Mapped to the `theme=dark` query parameter |
| `YoutubeEmbedPlayer` | Supported | Mapped to the YouTube player `theme` setting unless you override `theme` manually |
| Facebook / Instagram / Threads | Not supported | Meta oEmbed endpoints do not expose a package-level dark-mode switch here |
| Spotify | Not supported | Current oEmbed endpoint ignores package brightness |
| TikTok | Not supported | Current oEmbed and native player integrations do not map brightness |
| Vimeo | Not supported | Current oEmbed endpoint ignores package brightness |
| SoundCloud | Not supported | Current oEmbed endpoint ignores package brightness |
| Dailymotion / Giphy / NYTimes / generic oEmbed providers | Not supported | No package-level brightness mapping is currently implemented |

## Supported Providers

`flutter_oembed` ships with verified support for these provider groups:

| Category | Providers |
| :--- | :--- |
| Social | X, Facebook, Instagram, Threads, Reddit, TikTok videos and creator profiles, Tumblr |
| Video | YouTube, Vimeo, Dailymotion |
| Audio | Spotify, SoundCloud |
| Media / News | Flickr, Giphy, The New York Times |

## Getting Started

Wrap your app in an `EmbedScope` to provide global configuration:

```dart
final embedRouteObserver = RouteObserver<ModalRoute<dynamic>>();

EmbedScope(
  config: EmbedConfig(
    facebookAppId: 'YOUR_APP_ID',
    facebookClientToken: 'YOUR_CLIENT_TOKEN',
    pauseOnRouteCover: true,
    routeObserver: embedRouteObserver,
  ),
  child: MyApp(),
)
```

Then attach the same observer to your app navigator:

```dart
MaterialApp(
  navigatorObservers: [embedRouteObserver],
  home: const MyHomePage(),
)
```

Then render content with `EmbedCard`:

```dart
EmbedCard(
  url: 'https://twitter.com/X/status/1328842765115920384',
  embedType: EmbedType.x,
  onLinkTap: (url, data) {
    debugPrint('Intercepted external link: $url');
  },
)
```

If you need to override provider discovery or fetch behavior, inject your own
`IEmbedService` implementation through `EmbedConfig.embedService`:

```dart
final myEmbedService = MyEmbedService();

EmbedScope(
  config: EmbedConfig(
    embedService: myEmbedService,
  ),
  child: MyApp(),
)
```

## WebView Navigation Policy

`flutter_oembed` keeps a strict boundary around the embed WebView:

- `about:blank`, `data:`, `blob:`, and sub-frame navigations stay inside the WebView so provider scripts and nested iframes can initialize correctly.
- Unexpected main-frame redirects are blocked while the embed is still loading to avoid auto-redirect hijacks.
- Once loaded, external main-frame navigations are prevented inside the WebView and only handed off to the host app when they follow a recent user tap captured inside the embed. The package prefers href-specific JavaScript capture and falls back to a coarse Flutter-side pointer signal when needed.
- Passive post-load redirects, ad hops, and background deep-link attempts are blocked instead of being auto-launched.
- If you do not provide `onLinkTap`, the package attempts to open intercepted links with the platform's external browser or native app via `url_launcher`.
- If you provide `onLinkTap`, your callback becomes responsible for deciding what to do with that intercepted URL.

Use `EmbedConfig.onNavigationRequest` only when you need to override this policy completely.

## Sizing And Height Constraints

`flutter_oembed` derives embed height from provider metadata, measured WebView
content height, or provider-specific fallbacks. You can override that behavior
per embed with `EmbedConstraints`.

```dart
EmbedCard.url(
  'https://open.spotify.com/track/4JOEMgLkrHp8K1XNmyNffH',
  embedConstraints: const EmbedConstraints(
    preferredHeight: 232,
    minHeight: 180,
    maxHeight: 320,
  ),
)
```

Use `preferredHeight` when you want a stable initial size. Add `minHeight`
and `maxHeight` when the embed can resize but should stay within bounds.
When no explicit height is supplied, the widget starts from provider metadata
if available and then promotes measured WebView content height once the embed
finishes rendering.

`embedHeight` is still accepted as a legacy shorthand, but new code should use
`embedConstraints: EmbedConstraints(preferredHeight: ...)`.

## Lazy Loading

By default, `flutter_oembed` initializes the WebView as soon as the widget is
built. To improve performance in long lists or complex pages, you can enable
lazy loading to delay WebView initialization until the widget enters the
viewport:

```dart
EmbedScope(
  config: const EmbedConfig(
    lazyLoad: true,
  ),
  child: MyFeed(),
)
```

You can also override this per-embed:

```dart
EmbedCard.url(
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  lazyLoad: true,
)
```

When lazy loading is enabled, the widget shows a placeholder (defaults to a
`CircularProgressIndicator`) until it becomes visible. You can customize this
placeholder via `EmbedStyle.lazyLoadPlaceholderBuilder`.

## Provider Specific Parameters

You can fine-tune the native player or embed behavior for supported providers using `embedParams`. This is useful for customizing controls, autoplay behavior, or themes directly at the provider level.

```dart
EmbedCard.url(
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  embedParams: const YoutubeEmbedParams(
    controls: true,
    autoplay: false,
    theme: 'dark',
  ),
)
```

The package provides strongly-typed param classes including:
- `YoutubeEmbedParams`
- `TiktokEmbedParams`
- `XEmbedParams`
- `SoundcloudEmbedParams`
- `MetaEmbedParams`
- `VimeoEmbedParams`

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
  pauseOnRouteCover: true, // Pauses supported media when a new page or bottom sheet covers the route
  routeObserver: embedRouteObserver,
  heightUpdateDeltaThreshold: 2, // Ignores tiny downward height shifts to reduce jitter
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

### Cache Management

By default, `flutter_oembed` uses an **in-memory** cache that does not persist across
app restarts. This ensures the core library remains lightweight and has zero
mandatory storage dependencies.

You can manage this cache via `EmbedScope`:

```dart
// Clear the entire in-memory response cache
await EmbedScope.clearCache();

// Evict a specific URL from the cache
await EmbedScope.evictCacheForUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
```

#### Persistent Caching (Showcase)

If you need persistence, you can easily plug in a storage library like `hive_ce`
or `flutter_cache_manager` by implementing `EmbedCacheProvider`.

The example app provides showcase implementations that you can copy into your project:

- **Hive CE**: Lightweight pure-Dart NoSQL database
- **Flutter Cache Manager**: Popular file-based cache manager (support cache eviction and expiry)

To use a custom provider:

```dart
EmbedScope(
  config: EmbedConfig(
    cacheProvider: MyPersistentCacheProvider(),
  ),
  child: const MyApp(),
)
```

There are two ways to disable caching:

1. **Via Config**: Set `enabled: false` in `EmbedCacheConfig`. This prevents individual requests from checking or saving to the cache.
2. **Via Cache Backend**: Set `cacheProvider: EmbedCacheProvider.never()` in `EmbedConfig`. This replaces the storage layer for that scope with a no-op provider.

```dart
EmbedScope(
  config: EmbedConfig(
    cacheProvider: EmbedCacheProvider.never(),
  ),
  child: const MyApp(),
)
```

You can also provide your own `EmbedCacheProvider` implementation in
`EmbedConfig` when you need a custom cache backend per scope or test.

If you want to preserve an embed's attached WebView across widget remounts,
hold on to an `EmbedController` and pass the same controller back to the same
content later. This is the pattern used by the example app's HTML integration.

```dart
final controllersByUrl = <String, EmbedController>{};

EmbedController controllerForUrl(String url) {
  return controllersByUrl.putIfAbsent(url, EmbedController.new);
}

EmbedCard.url(
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  controller: controllerForUrl(
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  ),
)
```

This is controller-driven reuse, not an `EmbedScope`-managed WebView pool. The
package does not currently expose a scope-level `reuseWebViews` or
`maxReusedWebViews` API.

### Customizable Strings

You can customize or localize the user-facing text used by the package for
loading, errors, and accessibility via `EmbedStrings`:

```dart
EmbedConfig(
  strings: EmbedStrings(
    loadingSemanticsLabel: 'Cargando contenido...',
    retryHint: 'Toca dos veces para reintentar',
  ),
)
```

## Programmatic Media Control

If you keep a reference to an `EmbedController`, you can issue best-effort media
commands after the embed has been mounted. This is most reliable with
`TikTokEmbedPlayer` and TikTok `player/v1` embeds.

```dart
final controller = EmbedController();

await controller.pauseMedia();
await controller.resumeMedia();
await controller.muteMedia();
await controller.unmuteMedia();
```

These calls are no-ops until the controller is bound to a rendered embed. Other
providers may support only pause/resume, or may fall back to provider-defined
best-effort behavior.

You can also hydrate a controller with pre-fetched oEmbed data so the widget
reuses that payload instead of fetching it again:

```dart
final controller = EmbedController()
  ..setEmbedData(
    const EmbedData(
      html: '<blockquote>Preloaded embed</blockquote>',
      providerUrl: 'https://publish.twitter.com',
    ),
  );

EmbedCard.url(
  'https://twitter.com/X/status/1328842765115920384',
  controller: controller,
)
```

Controller-provided data is cleared automatically when
`controller.synchronize(contentKey: ...)` changes to a different embed.

## Custom Provider Rules

If you need to support a provider that is not part of the verified built-in
set, you can explicitly configure your `EmbedProviderConfig.providers` list.

The package exposes an `EmbedProviders` utility to easily access `EmbedProviders.verified` 
or `EmbedProviders.all`. You can use standard dart list manipulation or our `.append()` 
extension to merge your own `EmbedProviderRule`.

The example app includes a few practical recipes:

- CodePen as a provider that is not bundled in this package registry
- Pinterest with `pin.it` short-link support
- Bluesky Social for modern social protocol support
- Flickr with explicit `flickr.com` and `flic.kr` matching
- Tumblr for allowlist-driven integrations
- TED as a scoped trial of a provider you may not want to enable globally
- audio.com for audio-focused oEmbed examples

Pinterest is a practical starting point. The default registry doesn't include it, 
but a custom rule lets you support Pinterest explicitly and handle short links like `pin.it`.

```dart
EmbedScope(
  config: EmbedConfig(
    providers: EmbedProviderConfig(
      providers: EmbedProviders.verified.append([
        EmbedProviderRule(
          providerName: 'Pinterest',
          pattern: r'^(https?:\/\/(?:www\.)?pinterest\.com\/.*|https?:\/\/pin\.it\/.*)$',
          endpoint: 'https://www.pinterest.com/oembed.json',
        ),
      ]),
    ),
  ),
  child: EmbedCard.url('https://www.pinterest.com/pin/36739528211842807/'),
)
```

You can use the same pattern for any other oEmbed-compatible provider. Simply provide
the endpoints or use `iframeUrlBuilder`, `subRules`, or a custom `apiFactory` if the 
provider requires complex API logic.

Because you have direct control over the `providers` list, you can restrict the app to 
only load certain platforms:
```dart
providers: EmbedProviders.verified.where((r) => {'YouTube', 'Spotify'}.contains(r.providerName)).toList(),
```

## Debug Logging

Enable debug logging when you need visibility into provider resolution, cache hits, network requests, WebView loading events, and media-control decisions (pause/resume, route-cover, focus changes):

```dart
EmbedConfig(
  logger: const EmbedLogger.debug(),
)
```

You can also forward logs to your own logger:

```dart
EmbedConfig(
  onLinkTap: (url, data) {
    debugPrint('Intercepted $url on $data');
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
- direct TikTok video and creator profile samples using the same TikTok oEmbed flow

See the example app in `/example` for concrete integration code.

## Troubleshooting

- If Meta embeds fail, verify your App ID and Client Token first.
- If a provider resolves but renders an empty frame, enable debug logging and inspect WebView/network events.
- If taps should open inside your own router instead of the system browser/app, provide `onLinkTap` or a full `onNavigationRequest` override.
- If a URL is not matched, provide a custom provider rule to support it.
- If you need Flutter Web support, this package does not provide it yet.

## Additional Information

- pub.dev: [https://pub.dev/packages/flutter_oembed](https://pub.dev/packages/flutter_oembed)
- Example app: `/example`
- Release checklist: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
