import 'package:oembed/src/models/embed_enums.dart';
import 'package:equatable/equatable.dart';

import 'package:oembed/src/utils/embed_matchers.dart';

class EmbedLoaderParam extends Equatable {
  final String url;
  final EmbedType embedType;
  final double width;

  EmbedLoaderParam({
    required this.url,
    EmbedType? embedType,
    required double width,
  })  : embedType = embedType ?? EmbedMatchers.getEmbedType(url),
        width = _normalizeWidth(width);

  @override
  List<Object?> get props => [url, embedType, width];

  static double _normalizeWidth(double width) {
    return width.floorToDouble();
  }
}
