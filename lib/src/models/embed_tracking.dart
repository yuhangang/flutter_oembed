import 'package:equatable/equatable.dart';

/// Holds tracking, analytics, and instance markers for social embeds.
class EmbedTracking extends Equatable {
  /// Identifier for the page/screen this embed appears on.
  /// Used for analytics and gating (e.g. `EmbedDelegate`).
  final String? pageIdentifier;

  /// Source string passed to link-click callbacks. Defaults to `'embed'`.
  final String? source;

  /// Content ID for the host-app entity that contains this embed.
  final String? contentId;

  /// Optional DOM element identifier when multiple embeds of the same URL
  /// appear on the same page.
  final String? elementId;

  const EmbedTracking({
    this.pageIdentifier,
    this.source,
    this.contentId,
    this.elementId,
  });

  @override
  List<Object?> get props => [
    pageIdentifier,
    source,
    contentId,
    elementId,
  ];

  /// Creates a copy of this tracking object with optional new values.
  EmbedTracking copyWith({
    String? pageIdentifier,
    String? source,
    String? contentId,
    String? elementId,
  }) {
    return EmbedTracking(
      pageIdentifier: pageIdentifier ?? this.pageIdentifier,
      source: source ?? this.source,
      contentId: contentId ?? this.contentId,
      elementId: elementId ?? this.elementId,
    );
  }
}
