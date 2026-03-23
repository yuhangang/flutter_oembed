import 'package:oembed/data/oembed_apis.dart';
import 'package:oembed/data/oembed_data.dart';
import 'package:oembed/domain/entities/embed_enums.dart';
import 'package:oembed/domain/entities/embed_loader_param.dart';
import 'package:oembed/oembed_delegate.dart';

class OembedService {
  static Future<OembedData> getResult({
    required EmbedLoaderParam param,
    required OembedDelegate delegate,
  }) async {
    final BaseOembedApi api = getOembedApiByEmbedType(param, delegate);

    final result = await api.getOembedData(
      param.url,
      locale: delegate.getLocaleLanguageCode(),
      brightness: delegate.getAppBrightness(),
    );

    return result;
  }

  static BaseOembedApi getOembedApiByEmbedType(EmbedLoaderParam param, OembedDelegate delegate) {
    switch (param.embedType) {
      case EmbedType.tiktok:
        return TikTokEmbedApi();

      case EmbedType.facebook_video:
      case EmbedType.facebook_post:
      case EmbedType.facebook:
      case EmbedType.instagram:
        return MetaEmbedApi(param.embedType, param.width, delegate.facebookAppId, delegate.facebookClientToken);

      case EmbedType.x:
        return XEmbedApi();

      default:
        throw Exception('Invalid embed type');
    }
  }
}
