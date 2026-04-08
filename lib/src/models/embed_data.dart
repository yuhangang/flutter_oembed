import 'package:equatable/equatable.dart';

class EmbedData extends Equatable {
  final String html;
  final String? url;
  final String? thumbnailUrl;
  final String? title;
  final String? authorName;
  final String? authorUrl;
  final String? providerName;
  final String? providerUrl;
  final String? type;
  final double? width;
  final double? height;
  final double? cacheAge;

  const EmbedData({
    required this.html,
    this.url,
    this.thumbnailUrl,
    this.title,
    this.authorName,
    this.authorUrl,
    this.providerName,
    this.providerUrl,
    this.type,
    this.width,
    this.height,
    this.cacheAge,
  });

  @override
  List<Object?> get props => [
        html,
        url,
        thumbnailUrl,
        title,
        authorName,
        authorUrl,
        providerName,
        providerUrl,
        type,
        width,
        height,
        cacheAge,
      ];

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory EmbedData.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final url = json['url'];
    var html = json['html'] ?? '';

    // Fallback for 'photo' oEmbed type if HTML is missing
    if (html.isEmpty && type == 'photo' && url != null) {
      html = '<img src="$url" style="max-width: 100%; height: auto;" />';
    }

    return EmbedData(
      html: html,
      url: url,
      thumbnailUrl: json['thumbnail_url'],
      title: json['title'],
      authorName: json['author_name'],
      authorUrl: json['author_url'],
      providerName: json['provider_name'],
      providerUrl: json['provider_url'],
      type: type,
      width: _parseDouble(json['width']),
      height: _parseDouble(json['height']),
      cacheAge: _parseDouble(json['cache_age']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'html': html,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'title': title,
      'author_name': authorName,
      'author_url': authorUrl,
      'provider_name': providerName,
      'provider_url': providerUrl,
      'type': type,
      'width': width,
      'height': height,
      'cache_age': cacheAge,
    };
  }

  EmbedData copyWith({
    String? html,
    String? url,
    String? thumbnailUrl,
    String? title,
    String? authorName,
    String? authorUrl,
    String? providerName,
    String? providerUrl,
    String? type,
    double? width,
    double? height,
    double? cacheAge,
  }) {
    return EmbedData(
      html: html ?? this.html,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorUrl: authorUrl ?? this.authorUrl,
      providerName: providerName ?? this.providerName,
      providerUrl: providerUrl ?? this.providerUrl,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
      cacheAge: cacheAge ?? this.cacheAge,
    );
  }

  Duration? get cacheAgeDuration {
    if (cacheAge != null) {
      return Duration(seconds: cacheAge!.toInt());
    }

    return null;
  }

  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }
}
