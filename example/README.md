# flutter_oembed example

Example app for the `flutter_oembed` package.

## Run

```bash
flutter pub get
flutter run
```

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
