# `flutter_oembed` Development Roadmap

## Objective
To outline the strategic development path for `flutter_oembed` based on user priorities. The primary focus for the upcoming releases will be **Enhanced Provider Features** and **Stability & Performance**, ensuring the package is robust, highly customizable, and performant before advancing to 1.0.0 stable. 

New native provider integrations are paused for the immediate future to focus on perfecting the core architecture and existing provider support.

---

## 1. Phase 1: Stability & Performance (Current Priority)
This phase addresses core engine optimizations, focusing on the `EmbedWebViewDriver`, visibility tracking, and caching mechanisms.

### 1.1 WebView Lifecycle & Error Handling
- **Refine `EmbedWebViewDriver`**: Improve the reliability of the `WebView` lifecycle, particularly around cleanup during `dispose()` and handling aggressive garbage collection on low-end devices.
- **Enhanced `EmbedError` structure**: Standardize network timeouts, SSL errors, and JavaScript injection failures under the new `EmbedError` model to provide more actionable callbacks to the developer.
- **Memory Leak Prevention**: Audit `WebViewController` instances to ensure zero memory leaks during rapid scrolling in `ListView`s.

### 1.2 Rendering & Layout Performance
- **`LazyEmbedNode` Optimization**: Fine-tune the intersection observer/visibility detection logic. Ensure embeds do not block the UI thread while calculating dimensions.
- **Height Calculation Heuristics**: Improve the fallback logic when a provider fails to emit a valid `HeightChannel` message.

### 1.3 Caching Architecture
- **Multi-tiered Caching**: Differentiate between caching the API response (oEmbed JSON) and caching the actual WebView assets (HTML/JS/CSS).
- **Cache Invalidation**: Implement robust cache invalidation strategies for the `EmbedCacheConfig` to ensure users don't see stale embeds.

---

## 2. Phase 2: Enhanced Provider Features
This phase focuses on enriching the feature set of currently supported providers (Meta, Spotify, TikTok, YouTube, X, etc.) to offer a more native-feeling experience.

### 2.1 Unified Media Controls API
- **Problem**: Currently, the package auto-pauses media when it leaves the viewport, but lacks a public API for developers to trigger play/pause/mute manually.
- **Solution**: Expose an `EmbedMediaController` that standardizes media commands across `iframe` and `WebView` render modes, interacting with the underlying provider's JavaScript APIs (e.g., YouTube iFrame API, Vimeo Player.js).

### 2.2 Global Brightness & Theming Support
- **Problem**: `EmbedConfig.brightness` is currently only supported by X, Reddit, and YouTube.
- **Solution**: Implement custom CSS injection and JS theme mapping for providers that lack native oEmbed theme parameters (e.g., Spotify, TikTok, Vimeo, Meta). Ensure dark/light mode transitions are seamless.

### 2.3 Deep Linking & Native Intents
- **Enhance `onLinkTap`**: Improve the interception of URLs inside the WebView.
- **App-to-App Handoff**: Provide an optional, built-in mechanism to launch the native app (e.g., Spotify app, X app) if the user taps the embed and the app is installed, falling back to the browser if not.

---

## 3. Phase 3: Testing & Quality Assurance
Solidifying the package for a production-ready `1.0.0` stable release.

### 3.1 Comprehensive Test Coverage
- **Unit Testing**: Expand coverage for the new `EmbedWebViewDriver` state transitions and `EmbedService` caching logic.
- **Widget Testing**: Ensure `LazyEmbedNode` correctly mounts and unmounts based on mock visibility events.
- **Integration Testing**: Expand `embed_pipeline_test.dart` to cover network failure scenarios and fallback rendering.

### 3.2 Example App Revamp
- **Interactive Demos**: Update the example app's `settings_sheet.dart` to showcase the new Media Controls API and Brightness toggles across all providers.
- **Performance Profiling**: Add a "Stress Test" tab in the example app rendering 50+ mixed embeds in a `CustomScrollView` to benchmark memory usage and frame drops.

---

## Postponed Features (Future Roadmap)
- **Desktop/Web Support**: Verifying macOS, Windows, Linux, and implementing an iframe-based fallback for Flutter Web.
- **New Native Providers**: Adding specific integrations for Twitch, Pinterest, Apple Music, etc.