import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';

/// Per-widget visual customization for OEmbed embeds.
///
/// When provided to [EmbedCard] or [EmbedRenderer], these builders override
/// global rendering properties, making [EmbedScope] optional for
/// simple usage.
class EmbedStyle extends Equatable {
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

  /// Shown while the widget is waiting to enter the viewport when [lazyLoad] is true.
  /// If null, it falls back to [loadingBuilder], then to an empty [SizedBox].
  final WidgetBuilder? lazyLoadPlaceholderBuilder;

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

  /// Wraps the internal WebView widget. Use this to add borders, border radius,
  /// or other decorations specifically to the webview content.
  final Widget Function(BuildContext context, Widget child)? webViewBuilder;

  /// Convenience border radius applied by the default wrapper when
  /// [wrapperBuilder] is null.
  final BorderRadius? borderRadius;

  /// The maximum height of the embed when [scrollable] is true.
  /// Defaults to [kDefaultMaxScrollableEmbedHeight].
  final double maxScrollableHeight;

  const EmbedStyle({
    this.wrapperBuilder,
    this.loadingBuilder,
    this.lazyLoadPlaceholderBuilder,
    this.errorBuilder,
    this.footerBuilder,
    this.webViewBuilder,
    this.borderRadius,
    this.maxScrollableHeight = kDefaultMaxScrollableEmbedHeight,
  });

  @override
  List<Object?> get props => [borderRadius, maxScrollableHeight];

  /// Returns a copy of this style with the given fields replaced.
  EmbedStyle copyWith({
    Widget Function(BuildContext context, Widget child)? wrapperBuilder,
    WidgetBuilder? loadingBuilder,
    WidgetBuilder? lazyLoadPlaceholderBuilder,
    Widget Function(BuildContext context, Object? error)? errorBuilder,
    Widget Function(BuildContext context, String url)? footerBuilder,
    Widget Function(BuildContext context, Widget child)? webViewBuilder,
    BorderRadius? borderRadius,
    double? maxScrollableHeight,
  }) {
    return EmbedStyle(
      wrapperBuilder: wrapperBuilder ?? this.wrapperBuilder,
      loadingBuilder: loadingBuilder ?? this.loadingBuilder,
      lazyLoadPlaceholderBuilder:
          lazyLoadPlaceholderBuilder ?? this.lazyLoadPlaceholderBuilder,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      webViewBuilder: webViewBuilder ?? this.webViewBuilder,
      borderRadius: borderRadius ?? this.borderRadius,
      maxScrollableHeight: maxScrollableHeight ?? this.maxScrollableHeight,
    );
  }
}
