## 1.0.1-beta.2

### Features
* **Lazy Loading**: Implemented `LazyEmbedNode` for `EmbedCard`, enabling embeds to load only when they enter the viewport for better performance.
* **Embed Constraints**: Added `EmbedConstraints` to allow fine-grained control over the dimensions (min/max width/height) of rendered embeds.
* **Customizable Strings**: Introduced `EmbedStrings` for localizing or customizing error messages and UI text components.
* **Provider Automation**: Added a new generator tool for OEmbed provider configurations.

### Improvements
* **Stability**: Major overhaul of error handling with the new `EmbedError` structure.
* **Reliability**: Improved `EmbedWebViewDriver` for more robust lifecycle and state management.
* **WebView**: Enhanced `EmbedWebView` for better error recovery and loading states.
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
