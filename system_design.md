# `flutter_oembed` System Design & Flow

## Architectural Overview

`flutter_oembed` is a Flutter package that enables rendering rich social media and media content using oEmbed APIs and WebView-based rendering. The architecture is designed to handle fetching data from various oEmbed providers, caching API responses, managing dynamic layout configurations, and coordinating interactions with the native platform WebView.

### Core Components

1. **Presentation Layer (Widgets)**
   - **`EmbedCard`**: The primary user-facing widget used to embed content. It accepts the target content URL and merges its local configurations with the global configuration.
   - **`EmbedWidgetLoader`**: An internal orchestrator that connects global states with the widgets. Depending on the resolution strategy, it hands off rendering to a native widget player (e.g., `YoutubeEmbedPlayer`, `TiktokEmbedPlayer`), a direct Iframe renderer, or the standard `EmbedDataLoader` that fetches layout representations from the provider API.
   - **`EmbedScope`**: An `InheritedWidget` that supplies sweeping, global configurations across the app (like `EmbedConfig`, global caching strategies, navigation overrides, lazy-load settings, and visual themes).

2. **Control & Coordination Layer**
   - **`EmbedController`**: Serves as the mutable state object over the lifecycle of an embed. It observes network loading states, records internal errors, manages embed dimension parameters resulting from UI mutations, and exposes high-level, best-effort commands to control media instances (e.g., playing, pausing, muting).
   - **`EmbedWebView` & `EmbedWebViewControls`**: Encapsulates `webview_flutter` instances. Responsible for registering callbacks, dispatching user interaction metrics, and interpreting Javascript channel signals directly from within the inner DOM tree.
   - **`EmbedWebViewDriver`**: Provides a robust abstraction bridging the gap between web interactions and Flutter's widget lifecycle. It deals robustly with lifecycle events such as route-cover pausing behavior and active focus polling strategies.

3. **Service / Network / Routing Layer**
   - **`EmbedService`**: The core data dispatcher deciding how a specific URL should be mapped and fetched algorithmically.
   - **`ProviderRegistry`**: Evaluates requested URLs against custom developer rules and hardcoded API definitions. Matches regular expressions and domain paths for canonical oEmbed providers.
   - **`EmbedCacheProvider`**: Handles persistent network response caching logic. It supports customizable backend engines (`flutter_cache_manager` by default) to dramatically reduce latency and repetitive layout jittering constraints by serving localized HTML representations instantly.

---

## Data Flow & Lifecycle Initialization

The following sequence details how an embed is initialized, resolved, requested, and rendered back on screen.

```mermaid
sequenceDiagram
    participant UserApp as Application Code
    participant Loader as EmbedWidgetLoader
    participant DataLoader as EmbedDataLoader
    participant Controller as EmbedController
    participant Service as EmbedService
    participant Cache as EmbedCacheProvider
    participant API as OEmbed Endpoint
    participant Native as Native Widget Player
    participant WebView as EmbedWebView
    
    UserApp->>Loader: EmbedCard.url('https://...')
    Loader->>Controller: Synchronize Controller parameters (notify: false)
    
    Loader->>Service: resolveRender(url)
    Service->>Service: ProviderRegistry lookup (Regex)
    
    alt OEmbed Rendering Mode
        Service-->>Loader: Yield OEmbedRenderer
        Loader->>DataLoader: Instantiate EmbedDataLoader
        DataLoader->>DataLoader: didChangeDependencies() [Lifecycle Deferred]
        DataLoader->>Service: getResult()
        Service->>Cache: Query Network Response Cache
        alt Cache Miss
            Cache->>API: HTTP GET (oEmbed URL params)
            API-->>Cache: Return metadata/HTML JSON
            Cache-->>Service: Persist and Cache payload
        end
        Cache-->>Service: Yield EmbedData model
        Service-->>DataLoader: Return EmbedData
        DataLoader->>WebView: Emplace Content (HTML) via EmbedWebView.data
    else Iframe Direct Mode
        Service-->>Loader: Yield IframeRenderer
        Loader->>WebView: Emplace Content (URL) via EmbedWebView.url
    else Native Mode
        Service-->>Loader: Yield NativeWidgetRenderer
        Loader->>Native: Construct native player (e.g. YouTube/TikTok)
    end
    
    opt WebView Path
        WebView->>WebView: Initiate platform-native WebView engine
        WebView->>WebView: Inject Scripts / Load representations
        WebView->>Controller: Emit content height metrics derived via JS
        WebView->>Controller: Transition sequence to Loaded state (if changed)
        Controller-->>Loader: Notify dimension deltas (Constraints update cycle)
        Loader-->>UserApp: Display correctly scaled Embed payload
    end
```

---

## WebView Navigation Handling Policy

Security is strongly mandated when executing untrusted scripts provided by general-purpose external media sources. Built-in logic isolates the host application against URL hijack vulnerabilities or unauthorized redirect attempts natively.

```mermaid
flowchart TD
    A[WebView Navigation Request] --> Z{"Is onNavigationRequest provided?"}
    Z -->|Yes| Y[Return Custom Decision Override]
    Z -->|No| B{"Is Sub-frame, data: or blob: ?"}
    B -->|Yes| C[Allow Request]
    B -->|No| D1{"Is state Loading and URL trusted or provider-owned?"}
    D1 -->|Yes| C
    D1 -->|No| D{"Is a passive Top-level / Initial Load Redirect ?"}
    D -->|Yes| E[Block to Prevent Redirection Hijacking]
    D -->|No| F{"Was the request preceded by an active pointer tap ?"}
    F -->|No| F1{"Does Provider explicitly allow internal navigation?"}
    F1 -->|Yes| C
    F1 -->|No| G[Block Silent Traversal attempt]
    F -->|Yes| H{"Is the app listening via onLinkTap?"}
    H -->|Yes| I[Dispatch targeted URL to onLinkTap handler]
    H -->|No| J[Launch using external System Browser via url_launcher]
```

## Styling and Scale Pipeline

1. **Initial Protocol Handling**: An embed is rendered using a default height or static definitions based on constraints. When an embed completes initial rendering passes, the library intercepts dimensions and parses provider sizing structures encoded inside JSON parameters (`width`/`height` attributes against aspect ratios).
2. **Dynamic DOM Adjustments**: `EmbedWebViewDriver` attaches JavaScript observers to watch changes in `document.body.scrollHeight`. These scripts signal discrete callbacks across webview channel interconnects.
3. **Adjustment Debouncing Cycles**: `EmbedController` consumes height variations. To avoid jank looping architectures caused by small sub-pixel rounding mismatches by mobile GPU compositors, values under the configurable `heightUpdateDeltaThreshold` constant are systematically ignored.
4. **Relayout Commitment**: Valid dimension mutations trigger state reconstruction updates via `AnimatedBuilder`, accurately scaling bounding boxes and snapping seamlessly on top of dynamically morphing web content layouts.
