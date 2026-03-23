import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:equatable/equatable.dart';

class EmbedLoaderParam extends Equatable {
  final String url;
  final EmbedType embedType;
  final double width;

  EmbedLoaderParam({
    required this.url,
    required this.embedType,
    required double width,
  }) : width = _normalizeWidth(width);

  @override
  List<Object?> get props => [url, embedType, width];

  static double _normalizeWidth(double width) {
    return width.floorToDouble();
  }
}
