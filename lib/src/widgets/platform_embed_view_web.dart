import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class PlatformEmbedView extends StatefulWidget {
  final String? url;
  final String? srcDoc;
  final VoidCallback? onLoaded;
  final ValueChanged<double>? onHeightUpdate;
  final void Function(Object error)? onError;

  const PlatformEmbedView({
    super.key,
    this.url,
    this.srcDoc,
    this.onLoaded,
    this.onHeightUpdate,
    this.onError,
  });

  @override
  State<PlatformEmbedView> createState() => _PlatformEmbedViewState();
}

class _PlatformEmbedViewState extends State<PlatformEmbedView> {
  static int _nextViewId = 0;

  late final String _viewType;
  late final web.HTMLIFrameElement _iframeElement;
  StreamSubscription<web.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _viewType = 'flutter_oembed_iframe_${_nextViewId++}';
    _iframeElement =
        web.document.createElement('iframe') as web.HTMLIFrameElement
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'hidden'
          ..allow =
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen'
          ..setAttribute('allowfullscreen', 'true')
          ..setAttribute('scrolling', 'no')
          ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin');

    if (widget.srcDoc != null && widget.srcDoc!.isNotEmpty) {
      _iframeElement.srcdoc = widget.srcDoc!.toJS;
    } else if (widget.url != null && widget.url!.isNotEmpty) {
      _iframeElement.src = widget.url!;
    }

    _iframeElement.onLoad.listen((_) {
      widget.onLoaded?.call();
    });
    _iframeElement.onError.listen((_) {
      widget.onError?.call(
        StateError('Failed to load embed iframe for ${widget.url ?? 'srcdoc'}'),
      );
    });

    _messageSubscription = web.window.onMessage.listen(_handleMessage);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframeElement,
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _handleMessage(web.MessageEvent event) {
    try {
      final dataStr = event.data.toString();
      if (!dataStr.startsWith('{')) return;

      final data = json.decode(dataStr);
      if (data is! Map) return;

      final type = data['type'];
      final payload = data['payload'];

      switch (type) {
        case 'height':
          final height = double.tryParse(payload.toString());
          if (height != null && height > 0) {
            widget.onHeightUpdate?.call(height);
          }
        case 'error':
          widget.onError?.call(StateError('Embed error: $payload'));
      }
    } catch (_) {
      // Ignore non-readable messages
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      key: widget.key,
      viewType: _viewType,
    );
  }
}
