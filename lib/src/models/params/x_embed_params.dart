import 'package:flutter_oembed/src/models/params/base_embed_params.dart';

/// Typed parameters for X (Twitter) oEmbed requests.
///
/// See: https://developer.x.com/en/docs/twitter-for-websites/oembed-api
class XEmbedParams extends BaseEmbedParams {
  const XEmbedParams({
    this.limit,
    this.maxwidth,
    this.maxheight,
    this.omitScript,
    this.lang,
    this.theme,
    this.chrome,
    this.ariaPolite,
    this.dnt,
  });

  /// Display up to N items where N is a value between 1 and 20 inclusive.
  final int? limit;

  /// Set the maximum width of the widget. Must be between 180 and 1200 inclusive.
  final int? maxwidth;

  /// Set the maximum height of the widget. Must be greater than 200.
  final int? maxheight;

  /// Do not include a script element in the response.
  final bool? omitScript;

  /// A supported X language code.
  final String? lang;

  /// When set to dark, the timeline is displayed with light text over a dark background.
  final String? theme;

  /// Remove a timeline display component with space-separated tokens.
  /// Valid values: noheader, nofooter, noborders, noscrollbar, transparent.
  final List<String>? chrome;

  /// Set an assertive ARIA live region politeness value for Tweets added to a timeline.
  final String? ariaPolite;

  /// When set to true, the timeline and its embedded page on your site are not used
  /// for purposes that include personalized suggestions and personalized ads.
  final bool? dnt;

  @override
  Map<String, String> toMap() {
    return {
      if (limit != null) 'limit': limit.toString(),
      if (maxwidth != null) 'maxwidth': maxwidth.toString(),
      if (maxheight != null) 'maxheight': maxheight.toString(),
      if (omitScript != null) 'omit_script': omitScript! ? '1' : '0',
      if (lang != null) 'lang': lang!,
      if (theme != null) 'theme': theme!,
      if (chrome != null && chrome!.isNotEmpty) 'chrome': chrome!.join(' '),
      if (ariaPolite != null) 'aria_polite': ariaPolite!,
      if (dnt != null) 'dnt': dnt.toString(),
    };
  }

  @override
  List<Object?> get props => [
        limit,
        maxwidth,
        maxheight,
        omitScript,
        lang,
        theme,
        chrome,
        ariaPolite,
        dnt,
      ];
}
