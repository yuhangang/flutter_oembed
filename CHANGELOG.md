## 1.0.1-beta.2

- Second beta release

## 1.0.1-alpha.6

- **WebView refresh**: Fixed manual WebView reloads so they re-enter the loading lifecycle before the existing navigation delegate evaluates the next main-frame request, preventing trusted refresh navigations from being misrouted as external links.
- **Lazy loading**: Fixed `LazyEmbedNode` so reused `EmbedCard` instances reset lazy visibility when their URL changes and can become immediately visible when a preloaded controller is already loaded.
- **Config reloads**: Fixed `EmbedDataLoader` so swapping runtime-only config identities such as `httpClient` invalidates the active fetch instead of reusing stale request state.
- **Accessibility**: Restored semantics labels for terminal embed errors surfaced by `EmbedWidgetLoader` after retry exhaustion.
- **Example**: Added an expandable embed showcase demonstrating how to use `webViewBuilder` to limit initial render height (e.g., 150px) with a "Show More" expansion toggle.


## 1.0.1-alpha.5

### Breaking Changes
- **Cache Management**: The core library is now **zero-dependency** for storage. The mandatory `flutter_cache_manager` dependency has been removed.
- **Default Cache**: The default `EmbedCacheProvider` is now an **in-memory** implementation (`InMemoryEmbedCacheProvider`). OEmbed responses will no longer persist across app restarts by default.

### Improvements
- **Storage Showcases**: Added showcase implementations for persistent caching using `hive_ce` and `flutter_cache_manager` in the `example/` project. Users can easily copy these into their projects if they need persistence.
- **TikTok Example**: Added a TikTok creator profile sample to the example app, reusing the existing TikTok oEmbed provider flow that already handles `https://www.tiktok.com/@handle` profile URLs.
- **Memory Safety**: `InMemoryEmbedCacheProvider` includes TTL (time-to-live) logic to prevent indefinite memory growth.
- **Local Proxy**: Added a Dart-based API proxy tool in `example/tools/local_proxy.dart` to assist with local development, credential security, and centralized rate limiting.
- **Service Injection**: Exported `IEmbedService` as public API and documented `EmbedConfig.embedService` so provider resolution and fetch behavior can be overridden per scope.

## 1.0.1-alpha.4

### Breaking Changes
- **Provider Resolution**: Refactored `EmbedProviderConfig` to use an explicit `providers` list instead of implicitly concatenating `enabledProviders`, `customProviders`, and `includeUnverified`.
- **Provider Registry**: The active providers list now defaults to `EmbedProviders.verified`. You can merge custom rules directly using `providers: EmbedProviders.verified.append([myRule])`. Dynamic discovery and `providers_snapshot.dart` have been removed.

### Improvements
- Refactored `EmbedController` into a runtime attachment controller so embed identity now lives with `EmbedWebView`/driver inputs instead of on the controller itself. This makes external controllers easier to reuse across rendered embeds without coupling them to a specific `SocialEmbedParam`.
- Example: Cached controllers in the HTML integration demo so toggling non-content styling like the border switch does not unnecessarily reload embedded WebViews.
- EmbedController: Added `setEmbedData()` / `clearEmbedData()` so controller-owned preloaded oEmbed data can seed the render pipeline without fetching the payload again.
- Documentation: Clarified that current WebView reuse is driven by app-owned `EmbedController` caching rather than an `EmbedScope`-level pooling API.

## 1.0.1-alpha.3

### Breaking Changes
- Removed `seekTo` functionality from WebView entirely.
- Removed `EmbedController.seekMediaTo(Duration position)`.
- Removed `EmbedWebViewControls.seekTo(Duration position)`.

### Improvements

* **Navigation**: Hardened WebView navigation handling so sub-frame/bootstrap loads still work, unexpected startup redirects are blocked, and post-load external links or custom schemes are only handed off outside the WebView after a recent user tap, with a Flutter-side touch fallback when href-specific capture is unavailable.
* **WebView controls**: Fixed `EmbedWebViewControls` so `onSeekTo` is exposed through a public `seekTo` method.
* **Retry handling**: Fixed WebView retry from `noConnection` state so it restarts the load timeout instead of reloading without a guard.
* **Visibility and route-cover behavior**: Synced navigation visibility blocking with `VisibilityDetector` updates and made route-cover pausing honor `EmbedConfig.pauseOnRouteCover`.
* **WebView lifecycle**: Simplified `EmbedWebView` lifecycle management by keying the internal state on content-affecting inputs and always forcing a reload when the WebView remounts.
* **EmbedController**: Added `EmbedConfig.heightUpdateDeltaThreshold` to tune how aggressively tiny downward WebView height changes are ignored.
* **EmbedController**: Fixed external-controller embeds so changing `embedParams` resets the controller and forces the WebView to reload even when cache configuration is supplied from `EmbedScope`.
* **Maintenance**: Refactored internal media control constants in `provider_strategies.dart` into their respective strategy classes for better namespacing and readability.

## 1.0.1-alpha.2

### Features

* **Cache Control**: Added `EmbedCacheProvider.never()` for easily disabling the caching layer.
* **Scoped Cache Providers**: Added `EmbedConfig.cacheProvider` so cache backends can be injected per scope instead of relying on a global singleton.
* **Route-aware pausing**: Added `EmbedConfig.pauseOnRouteCover` and `EmbedConfig.routeObserver` so supported embeds can pause media when a new page or modal bottom sheet covers the current route, then make a best-effort resume attempt when the route is uncovered again.
* **Focused media arbitration**: Added route-scoped focus coordination so when multiple embeds are visible on the same page, the highest-visibility embed is treated as focused and non-focused embeds are actively paused.
* **Media-control diagnostics**: Added structured logging for pause/resume requests, focus changes, and route-cover media events.


### Improvements

* **YouTube**: Fixed iframe-mode YouTube embeds in the HTML, Markdown, and Quill example integrations by aligning the embed host, origin, and referer used inside mobile WebViews.
* **TikTok**: Added an opt-in mechanism to use the specialized v1 player via `TikTokEmbedParams.useV1Player` in `EmbedCard`. Standard oEmbed remains the default for better out-of-the-box compatibility.
* **TikTok**: Switched TikTok `player/v1` media control to the documented host-to-player message contract and exposed best-effort `EmbedController` media control methods for attached embeds.
* **EmbedController**: Added `EmbedCard.controller` so app-level media control UIs can target the actual rendered embed instance, including Vimeo and TikTok `player/v1` in the example app.
* **Custom Providers**: Expanded the example app's custom-provider integration to include additional manual oEmbed registration recipes, including CodePen, Pinterest, Bluesky Social, Flickr, Tumblr, TED, and audio.com.
* **Sizing**: Fixed a WebView sizing edge case where provider-reported aspect ratios could override later measured DOM height, causing slight bottom clipping on providers such as Pinterest.


## 1.0.1-alpha

* Add alpha tag to the version as the library need more testing and refinement, apologies for my vibe coding slop.

### Features
* **Lazy Loading**: Implemented `LazyEmbedNode` for `EmbedCard`, enabling embeds to load only when they enter the viewport for better performance.
* **Embed Constraints**: Added `EmbedConstraints` to allow fine-grained control over the dimensions (min/max width/height) of rendered embeds.
* **Customizable Strings**: Introduced `EmbedStrings` for localizing or customizing error messages and UI text components.
* **Provider Automation**: Added a new generator tool for OEmbed provider configurations.
* **Cache Control**: Added `EmbedCacheProvider.never()` for easily disabling the caching layer.
* **Scoped Cache Providers**: Added `EmbedConfig.cacheProvider` so cache backends can be injected per scope instead of relying on a global singleton.
* **Route-aware pausing**: Added `EmbedConfig.pauseOnRouteCover` and `EmbedConfig.routeObserver` so supported embeds can pause media when a new page or modal bottom sheet covers the current route, then make a best-effort resume attempt when the route is uncovered again.
* **Focused media arbitration**: Added route-scoped focus coordination so when multiple embeds are visible on the same page, the highest-visibility embed is treated as focused and non-focused embeds are actively paused.
* **Media-control diagnostics**: Added structured logging for pause/resume requests, focus changes, and route-cover media events.

### Improvements
* **Stability**: Major overhaul of error handling with the new `EmbedError` structure.
* **Reliability**: Improved `EmbedWebViewDriver` for more robust lifecycle and state management.
* **WebView**: Enhanced `EmbedWebView` for better error recovery and loading states.
* **Navigation**: Hardened WebView navigation handling so sub-frame/bootstrap loads still work, unexpected startup redirects are blocked, and post-load external links or custom schemes are handed off outside the WebView.
* **YouTube**: Fixed iframe-mode YouTube embeds in the HTML, Markdown, and Quill example integrations by aligning the embed host, origin, and referer used inside mobile WebViews.
* **TikTok**: Added an opt-in mechanism to use the specialized v1 player via `TikTokEmbedParams.useV1Player` in `EmbedCard`. Standard oEmbed remains the default for better out-of-the-box compatibility.
* **TikTok**: Switched TikTok `player/v1` media control to the documented host-to-player message contract and exposed best-effort `EmbedController` media control methods for attached embeds.
* **EmbedController**: Added `EmbedCard.controller` so app-level media control UIs can target the actual rendered embed instance, including Vimeo and TikTok `player/v1` in the example app.
* **Custom Providers**: Expanded the example app's custom-provider integration to include additional manual oEmbed registration recipes, including CodePen, Pinterest, Bluesky Social, Flickr, Tumblr, TED, and audio.com.
* **Sizing**: Fixed a WebView sizing edge case where provider-reported aspect ratios could override later measured DOM height, causing slight bottom clipping on providers such as Pinterest.
* **Refactoring**: Significant cleanup of core components including `EmbedScope`, `EmbedController`, and `EmbedDataLoader`.

### Testing
* **Coverage**: Added unit tests across controllers, models, and services.
* **Integration**: Added `embed_pipeline_test.dart` to verify the end-to-end embedding process.

### Example
* **Settings**: Added a new interactive configuration menu to test different settings on the fly.
* **Redesign**: Overhauled the details page for better visualization of embed metadata.


## 1.0.0-beta

* Initial stable release of `flutter_oembed`.
* Supports X (Twitter), TikTok, Instagram, Facebook, YouTube, Spotify, Vimeo, and more.
* Provides `EmbedCard` widget for easy embedding.
* Built-in caching system for oEmbed responses.
* Customizable rendering modes (oEmbed vs Iframe).
* Global configuration via `EmbedScope`.
