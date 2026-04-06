import 'package:flutter_embed/src/models/embed_enums.dart';
import 'package:flutter_embed/src/models/base_embed_params.dart';
import 'package:flutter_embed/src/utils/embed_matchers.dart';
import 'package:flutter_embed/src/utils/embed_link_utils.dart';
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
  final Key key;
  final bool isTikTokPhoto;

  final Map<String, String>? queryParameters;
  final BaseEmbedParams? embedParams;

  SocialEmbedParam({
    required String url,
    EmbedType? embedType,
    Key? key,
    this.queryParameters,
    this.embedParams,
  })  : embedType = embedType ?? EmbedMatchers.getEmbedType(url),
        url =
            (embedType ?? EmbedMatchers.getEmbedType(url)) == EmbedType.youtube
                ? getYoutubeEmbedParam(url)
                : url,
        key = key ?? ValueKey(url),
        isTikTokPhoto = (embedType ?? EmbedMatchers.getEmbedType(url)) ==
                EmbedType.tiktok &&
            url.contains('/photo/');

  @override
  List<Object?> get props => [
        url,
        embedType,
        key,
        queryParameters,
        embedParams,
      ];
}
