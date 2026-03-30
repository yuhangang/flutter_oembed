import 'package:oembed/src/models/embed_enums.dart';
import 'package:oembed/src/utils/embed_matchers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

typedef EmbedLinkCallback =
    void Function(
      String url,
      EmbedType embedType,
      EmbedButtonLocation embedButtonLocation,
    );

class SocialEmbedParam extends Equatable {
  final String url;
  final EmbedType embedType;
  final String source;
  final String pageIdentifier;
  final String contentId;
  final Key key;

  final bool isTikTokPhoto;

  /// Extra key to perform disposal of the widget when needed
  final String? extraIdentifier;

  SocialEmbedParam({
    required this.url,
    EmbedType? embedType,
    required this.source,
    required this.contentId,
    required this.pageIdentifier,
    required String? elementId,
    required this.extraIdentifier,
  }) : embedType = embedType ?? EmbedMatchers.getEmbedType(url),
       key = ValueKey(
         '$pageIdentifier-$url-${elementId ?? url.hashCode.toString()}-$extraIdentifier',
       ),
       isTikTokPhoto = embedType == EmbedType.tiktok && url.contains('/photo/');

  @override
  List<Object?> get props => [key, extraIdentifier];
}
