import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/controllers/embed_controller.dart';

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
class NativeWidgetRenderer extends EmbedRenderer {
  final Widget Function(
    BuildContext context,
    double maxWidth,
    EmbedController controller,
  ) builder;

  const NativeWidgetRenderer(this.builder);
}
