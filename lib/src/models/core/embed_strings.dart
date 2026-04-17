import 'package:equatable/equatable.dart';

/// User-facing copy used by the package for loading, retry, and semantics.
///
/// Override these values from [EmbedConfig] when the host app needs localized
/// or product-specific messaging without replacing the package widgets.
class EmbedStrings extends Equatable {
  final String loadingSemanticsLabel;
  final String contentSemanticsLabel;
  final String retryAfterConnectionErrorSemanticsLabel;
  final String retryAfterLoadErrorSemanticsLabel;
  final String retryHint;
  final String notFoundSemanticsLabel;
  final String restrictedSemanticsLabel;
  final String networkErrorSemanticsLabel;
  final String genericLoadErrorSemanticsLabel;

  const EmbedStrings({
    this.loadingSemanticsLabel = 'Loading embedded content',
    this.contentSemanticsLabel = 'Embedded content',
    this.retryAfterConnectionErrorSemanticsLabel =
        'Retry embedded content after connection error',
    this.retryAfterLoadErrorSemanticsLabel =
        'Retry embedded content after load error',
    this.retryHint = 'Double tap to retry',
    this.notFoundSemanticsLabel = 'Embedded content not found',
    this.restrictedSemanticsLabel = 'Embedded content is restricted',
    this.networkErrorSemanticsLabel =
        'Embedded content failed to load because of a network error',
    this.genericLoadErrorSemanticsLabel = 'Embedded content failed to load',
  });

  @override
  List<Object?> get props => [
        loadingSemanticsLabel,
        contentSemanticsLabel,
        retryAfterConnectionErrorSemanticsLabel,
        retryAfterLoadErrorSemanticsLabel,
        retryHint,
        notFoundSemanticsLabel,
        restrictedSemanticsLabel,
        networkErrorSemanticsLabel,
        genericLoadErrorSemanticsLabel,
      ];

  EmbedStrings copyWith({
    String? loadingSemanticsLabel,
    String? contentSemanticsLabel,
    String? retryAfterConnectionErrorSemanticsLabel,
    String? retryAfterLoadErrorSemanticsLabel,
    String? retryHint,
    String? notFoundSemanticsLabel,
    String? restrictedSemanticsLabel,
    String? networkErrorSemanticsLabel,
    String? genericLoadErrorSemanticsLabel,
  }) {
    return EmbedStrings(
      loadingSemanticsLabel:
          loadingSemanticsLabel ?? this.loadingSemanticsLabel,
      contentSemanticsLabel:
          contentSemanticsLabel ?? this.contentSemanticsLabel,
      retryAfterConnectionErrorSemanticsLabel:
          retryAfterConnectionErrorSemanticsLabel ??
              this.retryAfterConnectionErrorSemanticsLabel,
      retryAfterLoadErrorSemanticsLabel: retryAfterLoadErrorSemanticsLabel ??
          this.retryAfterLoadErrorSemanticsLabel,
      retryHint: retryHint ?? this.retryHint,
      notFoundSemanticsLabel:
          notFoundSemanticsLabel ?? this.notFoundSemanticsLabel,
      restrictedSemanticsLabel:
          restrictedSemanticsLabel ?? this.restrictedSemanticsLabel,
      networkErrorSemanticsLabel:
          networkErrorSemanticsLabel ?? this.networkErrorSemanticsLabel,
      genericLoadErrorSemanticsLabel:
          genericLoadErrorSemanticsLabel ?? this.genericLoadErrorSemanticsLabel,
    );
  }
}
