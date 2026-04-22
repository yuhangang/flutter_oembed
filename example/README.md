# flutter_oembed example

Example app for the `flutter_oembed` package.

## Run

```bash
flutter pub get
flutter run
```

## Local CORS Proxy (Development)

For Flutter Web development, you may encounter CORS restrictions when fetching oEmbed data or assets. A local proxy is provided to bypass these during development.

### 1. Start the proxy

```bash
# From the project root
dart example/tools/local_proxy.dart
```

### 2. Configure the Example App

In the example app, go to **Settings > Global Settings** and set the **Proxy URL** to `http://localhost:8080/`.

> [!NOTE]
> This proxy is intended for local development only and should not be used in production.

## What To Check

1. Main list shows direct `EmbedCard` usage across providers.
2. TikTok samples include both a video embed and a creator profile embed using the same TikTok oEmbed pipeline.
3. App bar document icon opens Markdown integration (`markdown_widget`).
4. App bar code icon opens HTML integration (`flutter_html`).

## Markdown Integration Notes

- Uses a custom Markdown block syntax (`OembedBlockSyntax`) so `<oembed>` tags
  are parsed as nodes instead of plain text.
- Supports URL extraction from `url/href/src/data-url` attributes or inner
  text of `<oembed>...</oembed>`.

## HTML Integration Notes

- Uses `TagExtension(tagsToExtend: {"oembed"})`.
- Supports URL extraction from `url/href/src/data-url` attributes or inner
  text.
