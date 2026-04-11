import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_oembed/src/core/embed_cache_provider.dart';

/// Default implementation of [EmbedCacheProvider] using [flutter_cache_manager].
class DefaultEmbedCacheProvider implements EmbedCacheProvider {
  static final DefaultEmbedCacheProvider instance = DefaultEmbedCacheProvider();

  final BaseCacheManager _cacheManager;

  DefaultEmbedCacheProvider({BaseCacheManager? cacheManager})
      : _cacheManager = cacheManager ?? DefaultCacheManager();

  @override
  Future<Uint8List?> getFileFromCache(String key) async {
    final fileInfo = await _cacheManager.getFileFromCache(key);
    if (fileInfo != null) {
      return await fileInfo.file.readAsBytes();
    }
    return null;
  }

  @override
  Future<void> putFile(String key, Uint8List bytes, {Duration? maxAge}) async {
    await _cacheManager.putFile(
      key,
      bytes,
      maxAge: maxAge ?? const Duration(days: 30),
    );
  }

  @override
  Future<void> emptyCache() async {
    await _cacheManager.emptyCache();
  }

  @override
  Future<void> removeFile(String key) async {
    await _cacheManager.removeFile(key);
  }
}
