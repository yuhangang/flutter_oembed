import 'package:flutter_oembed/src/core/embed_service_interface.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/configs/embed_cache_config.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/embed_loader_param.dart';
import 'package:flutter_oembed/src/models/core/embed_renderer.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/models/params/base_embed_params.dart';
import 'package:flutter_oembed/src/services/embed_service.dart';
import 'package:http/http.dart' as http;

class FakeEmbedService extends EmbedServiceImpl implements IEmbedService {
  FakeEmbedService({
    this.getResultResponse,
    this.getResultError,
    this.resolveRenderResponse,
    this.resolveRuleResponse,
    this.resolveCacheUriResponse,
    this.resolveIframeUrlResponse,
  });

  final EmbedData? getResultResponse;
  final Object? getResultError;
  final EmbedRenderer? resolveRenderResponse;
  final EmbedProviderRule? resolveRuleResponse;
  final Uri? resolveCacheUriResponse;
  final String? resolveIframeUrlResponse;

  int getResultCallCount = 0;
  int resolveRenderCallCount = 0;
  int resolveRuleCallCount = 0;
  int resolveCacheUriCallCount = 0;
  int resolveIframeUrlCallCount = 0;

  EmbedConfig? lastGetResultConfig;
  EmbedConfig? lastResolveRenderConfig;
  EmbedConfig? lastResolveRuleConfig;
  EmbedConfig? lastResolveCacheUriConfig;

  @override
  Future<EmbedData> getResult({
    required EmbedLoaderParam param,
    EmbedConfig? config,
    EmbedLogger? logger,
    EmbedCacheConfig? cacheConfig,
    http.Client? httpClient,
  }) async {
    getResultCallCount += 1;
    lastGetResultConfig = config;
    if (getResultError != null) {
      throw getResultError!;
    }
    return getResultResponse ??
        super.getResult(
          param: param,
          config: config,
          logger: logger,
          cacheConfig: cacheConfig,
          httpClient: httpClient,
        );
  }

  @override
  Uri? resolveCacheUri(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    double? width,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
    EmbedLogger? logger,
  }) {
    resolveCacheUriCallCount += 1;
    lastResolveCacheUriConfig = config;
    return resolveCacheUriResponse ??
        super.resolveCacheUri(
          url,
          config: config,
          embedType: embedType,
          width: width,
          queryParameters: queryParameters,
          embedParams: embedParams,
          logger: logger,
        );
  }

  @override
  EmbedRenderer resolveRender(
    String url, {
    EmbedConfig? config,
    EmbedType? embedType,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    BaseEmbedParams? embedParams,
  }) {
    resolveRenderCallCount += 1;
    lastResolveRenderConfig = config;
    return resolveRenderResponse ??
        super.resolveRender(
          url,
          config: config,
          embedType: embedType,
          logger: logger,
          queryParameters: queryParameters,
          embedParams: embedParams,
        );
  }

  @override
  EmbedProviderRule? resolveRule(
    String url, {
    EmbedConfig? config,
  }) {
    resolveRuleCallCount += 1;
    lastResolveRuleConfig = config;
    return resolveRuleResponse ?? super.resolveRule(url, config: config);
  }

  @override
  String? resolveIframeUrl(
    String url, {
    EmbedConfig? config,
    EmbedLogger? logger,
    Map<String, String>? queryParameters,
    bool silent = false,
  }) {
    resolveIframeUrlCallCount += 1;
    return resolveIframeUrlResponse ??
        super.resolveIframeUrl(
          url,
          config: config,
          logger: logger,
          queryParameters: queryParameters,
          silent: silent,
        );
  }
}
