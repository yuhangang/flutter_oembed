import 'package:oembed/domain/entities/embed_enums.dart';

class EmbedWidgetState {
  final EmbedLoadingState loadingState;
  final bool didRetry;

  const EmbedWidgetState({
    required this.loadingState,
    required this.didRetry,
  });

  EmbedWidgetState copyWith({
    EmbedLoadingState? loadingState,
    bool? didRetry,
  }) {
    return EmbedWidgetState(
      loadingState: loadingState ?? this.loadingState,
      didRetry: didRetry ?? this.didRetry,
    );
  }
}
