class EmbedWebViewState {
  final double? height;
  final bool isVisible;

  const EmbedWebViewState({
    required this.height,
    required this.isVisible,
  });

  EmbedWebViewState copyWith({
    double? height,
    bool? isVisible,
  }) {
    return EmbedWebViewState(
      height: height ?? this.height,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
