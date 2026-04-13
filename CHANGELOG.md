## 1.0.1-alpha.2

### Features

* **Cache Control**: Added `EmbedCacheProvider.never()` for easily disabling the caching layer.
* **Scoped Cache Providers**: Added `EmbedConfig.cacheProvider` so cache backends can be injected per scope instead of relying on a global singleton.
* **Route-aware pausing**: Added `EmbedConfig.pauseOnRouteCover` and `EmbedConfig.routeObserver` so supported embeds can pause media when a new page or modal bottom sheet covers the current route, then make a best-effort resume attempt when the route is uncovered again.
* **Focused media arbitration**: Added route-scoped focus coordination so when multiple embeds are visible on the same page, the highest-visibility embed is treated as focused and non-focused embeds are actively paused.
* **Media-control diagnostics**: Added structured logging for pause/resume requests, focus changes, and route-cover media events.

### Improvements

* **WebView**: Added optional scope-level WebView reuse with explicit per-embed `reuseKey` support for remount-heavy UIs such as tabs and lists.
* **Navigation**: Hardened WebView navigation handling so sub-frame/bootstrap loads still work, unexpected startup redirects are blocked, and post-load external links or custom schemes are handed off outside the WebView.
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
* **WebView**: Added optional scope-level WebView reuse with explicit per-embed `reuseKey` support for remount-heavy UIs such as tabs and lists.
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
