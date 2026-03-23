class EmbedCoordinatorState {
  List<String> shownSocialEmbeds;
  List<String> shownElements;

  EmbedCoordinatorState({
    required this.shownSocialEmbeds,
    required this.shownElements,
  });

  EmbedCoordinatorState copyWith({
    List<String>? shownSocialEmbeds,
    List<String>? shownElements,
  }) {
    return EmbedCoordinatorState(
      shownSocialEmbeds: shownSocialEmbeds ?? this.shownSocialEmbeds,
      shownElements: shownElements ?? this.shownElements,
    );
  }

  bool showSocialEmbed(String url) {
    return shownSocialEmbeds.contains(url);
  }

  bool showElement(String url) {
    return shownElements.contains(url);
  }
}
