import 'package:flutter/material.dart';

/// Per-widget visual customization for OEmbed embeds.
///
/// When provided to [EmbedCard] or [EmbedRenderer], these builders override
/// the global [EmbedDelegate] builders, making [EmbedScope] optional for
/// users who want standalone embeds.
class EmbedStyle {
  /// Wraps the entire embed widget. Use this to add borders, border radius,
  /// shadows, padding, etc.
  ///
  /// ```dart
  /// wrapperBuilder: (context, child) => Card(
  ///   shape: RoundedRectangleBorder(
  ///     borderRadius: BorderRadius.circular(12),
  ///   ),
  ///   child: ClipRRect(
  ///     borderRadius: BorderRadius.circular(12),
  ///     child: child,
  ///   ),
  /// ),
  /// ```
  final Widget Function(BuildContext context, Widget child)? wrapperBuilder;

  /// Shown while the OEmbed data is being fetched or the WebView is loading.
  final WidgetBuilder? loadingBuilder;

  /// Shown when an error occurs (network error, 404, etc.).
  ///
  /// Receives the error object so the caller can display specific messages.
  final Widget Function(BuildContext context, Object? error)? errorBuilder;

  /// A widget shown below the embedded content, e.g. an "Open in app" button.
  ///
  /// ```dart
  /// footerBuilder: (context, url) => TextButton.icon(
  ///   onPressed: () => launchUrl(Uri.parse(url)),
  ///   icon: Icon(Icons.open_in_new, size: 14),
  ///   label: Text('Open in browser'),
  /// ),
  /// ```
  final Widget Function(BuildContext context, String url)? footerBuilder;

  /// Convenience border radius applied by the default wrapper when
  /// [wrapperBuilder] is null.
  final BorderRadius? borderRadius;
  
  /// The maximum height of the embed when [scrollable] is true.
  /// Defaults to 400.0.
  final double maxScrollableHeight;

  const EmbedStyle({
    this.wrapperBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.footerBuilder,
    this.borderRadius,
    this.maxScrollableHeight = 400.0,
  });

  /// Returns a copy of this style with the given fields replaced.
  EmbedStyle copyWith({
    Widget Function(BuildContext context, Widget child)? wrapperBuilder,
    WidgetBuilder? loadingBuilder,
    Widget Function(BuildContext context, Object? error)? errorBuilder,
    Widget Function(BuildContext context, String url)? footerBuilder,
    BorderRadius? borderRadius,
    double? maxScrollableHeight,
  }) {
    return EmbedStyle(
      wrapperBuilder: wrapperBuilder ?? this.wrapperBuilder,
      loadingBuilder: loadingBuilder ?? this.loadingBuilder,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      borderRadius: borderRadius ?? this.borderRadius,
      maxScrollableHeight: maxScrollableHeight ?? this.maxScrollableHeight,
    );
  }
}
