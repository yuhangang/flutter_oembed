## 1.0.1-alpha

* Add alpha tag to the version as the library need more testing and refinement, apologies for my vibe coding slop.

### Features
* **Lazy Loading**: Implemented `LazyEmbedNode` for `EmbedCard`, enabling embeds to load only when they enter the viewport for better performance.
* **Embed Constraints**: Added `EmbedConstraints` to allow fine-grained control over the dimensions (min/max width/height) of rendered embeds.
* **Customizable Strings**: Introduced `EmbedStrings` for localizing or customizing error messages and UI text components.
* **Provider Automation**: Added a new generator tool for OEmbed provider configurations.
* **Cache Control**: Added `EmbedCacheProvider.never()` for easily disabling the caching layer.
* **Scoped Cache Providers**: Added `EmbedConfig.cacheProvider` so cache backends can be injected per scope instead of relying on a global singleton.

### Improvements
* **Stability**: Major overhaul of error handling with the new `EmbedError` structure.
* **Reliability**: Improved `EmbedWebViewDriver` for more robust lifecycle and state management.
* **WebView**: Enhanced `EmbedWebView` for better error recovery and loading states.
* **YouTube**: Fixed iframe-mode YouTube embeds in the HTML, Markdown, and Quill example integrations by aligning the embed host, origin, and referer used inside mobile WebViews.
* **TikTok**: Fixed a regression where TikTok embeds default to using the specialized v1 player instead of standard oEmbed rendering.
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
