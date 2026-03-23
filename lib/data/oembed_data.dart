class OembedData {
  final String html;
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

  OembedData({
    required this.html,
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

  factory OembedData.fromJson(Map<String, dynamic> json) {
    return OembedData(
      html: json['html'],
      thumbnailUrl: json['thumbnail_url'],
      title: json['title'],
      authorName: json['author_name'],
      authorUrl: json['author_url'],
      providerName: json['provider_name'],
      providerUrl: json['provider_url'],
      type: json['type'],
      width: double.tryParse(json['width'].toString()),
      height: double.tryParse(json['height'].toString()),
      cacheAge: double.tryParse(json['cache_age'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'html': html,
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

  OembedData copyWith({
    String? html,
    String? thumbnailUrl,
    String? title,
    String? authorName,
    String? authorUrl,
    String? providerName,
    String? providerUrl,
    String? type,
    double? width,
    double? height,
  }) {
    return OembedData(
      html: html ?? this.html,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorUrl: authorUrl ?? this.authorUrl,
      providerName: providerName ?? this.providerName,
      providerUrl: providerUrl ?? this.providerUrl,
      type: type ?? this.type,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Duration? get cacheAgeDuration {
    if (cacheAge != null) {
      return Duration(seconds: cacheAge!.toInt());
    }

    return null;
  }
}
