import 'package:flutter/widgets.dart';

class PlatformEmbedView extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
