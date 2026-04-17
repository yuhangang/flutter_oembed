import 'package:flutter_oembed/src/models/core/provider_rule.dart';

/// Represents how an embed should be loaded and rendered by the standard pipeline.
sealed class EmbedRenderer {
  const EmbedRenderer();
}

/// The OEmbed API should be fetched, and its output parsed/injected into an iframe.
class OEmbedRenderer extends EmbedRenderer {
  const OEmbedRenderer();
}

/// The embed should be loaded directly via an iframe URL, bypassing the API.
class IframeRenderer extends EmbedRenderer {
  final String iframeUrl;
  const IframeRenderer(this.iframeUrl);
}

/// The embed should be rendered natively via a Flutter widget (e.g. YouTube).
///
/// The [identifier] is used by the UI layer to look up the appropriate widget builder.
/// The [context] provides the parameters required by the builder.
class NativeWidgetRenderer extends EmbedRenderer {
  final String identifier;
  final EmbedProviderContext context;

  const NativeWidgetRenderer(this.identifier, this.context);
}
