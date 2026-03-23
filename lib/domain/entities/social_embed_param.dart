import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';


typedef EmbedLinkCallback = void Function(
  String url,
  EmbedType embedType,
  EmbedButtonLocation embedButtonLocation,
);

class SocialEmbedParam extends Equatable {
  final String url;
  final EmbedType embedType;
  final EmbedContentType embedContentType;
  final String source;
  final String pageIdentifier;
  final String contentId;
  final Key key;

  final bool isTikTokPhoto;

  /// Extra key to perform disposal of the widget when needed
  final String? extraIdentifier;

  SocialEmbedParam({
    required this.url,
    required this.embedType,
    required this.embedContentType,
    required this.source,
    required this.contentId,
    required this.pageIdentifier,
    required String? elementId,
    required this.extraIdentifier,
  })  : key = ValueKey(
          '$pageIdentifier-$url-${elementId ?? url.hashCode.toString()}-$extraIdentifier',
        ),
        isTikTokPhoto =
            embedType == EmbedType.tiktok && url.contains('/photo/');

  @override
  List<Object?> get props => [key, extraIdentifier];
}
