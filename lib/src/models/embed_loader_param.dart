import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_embed/src/models/base_embed_params.dart';

import 'package:flutter_embed/src/utils/embed_matchers.dart';

class EmbedLoaderParam extends Equatable {
  final String url;
  final EmbedType embedType;
  final double width;
  final Map<String, String>? queryParameters;
  final BaseEmbedParams? embedParams;

  EmbedLoaderParam({
    required this.url,
    EmbedType? embedType,
    required double width,
    this.queryParameters,
    this.embedParams,
  })  : embedType = embedType ?? EmbedMatchers.getEmbedType(url),
        width = _normalizeWidth(width);

  @override
  List<Object?> get props => [
    url,
    embedType,
    width,
    queryParameters,
    embedParams,
  ];

  static double _normalizeWidth(double width) {
    return width.floorToDouble();
  }
}
