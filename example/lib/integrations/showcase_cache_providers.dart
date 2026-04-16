import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_oembed/flutter_oembed.dart';
import 'package:hive_ce/hive_ce.dart';

/// SHOWCASE: Persistent caching using [flutter_cache_manager].
///
/// This implementation uses the popular `flutter_cache_manager` package
/// to handle file storage, expiration, and cleanup.
class FlutterCacheManagerEmbedCacheProvider implements EmbedCacheProvider {
  final BaseCacheManager _cacheManager;

  FlutterCacheManagerEmbedCacheProvider({BaseCacheManager? cacheManager})
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

/// SHOWCASE: Persistent caching using [hive_ce].
///
/// This implementation uses `hive_ce` (pure Dart NoSQL database) to store
/// OEmbed responses. It is lightweight and perfect for structured data.
class HiveEmbedCacheProvider implements EmbedCacheProvider {
  final Box<Map> _box;

  HiveEmbedCacheProvider(this._box);

  @override
  Future<Uint8List?> getFileFromCache(String key) async {
    final data = _box.get(key);
    if (data == null) return null;

    final timestamp = data['timestamp'] as DateTime;
    final maxAge = data['maxAge'] as Duration;

    if (DateTime.now().difference(timestamp) > maxAge) {
      await _box.delete(key);
      return null;
    }

    return data['bytes'] as Uint8List;
  }

  @override
  Future<void> putFile(String key, Uint8List bytes, {Duration? maxAge}) async {
    await _box.put(key, {
      'bytes': bytes,
      'timestamp': DateTime.now(),
      'maxAge': maxAge ?? const Duration(days: 30),
    });
  }

  @override
  Future<void> emptyCache() async {
    await _box.clear();
  }

  @override
  Future<void> removeFile(String key) async {
    await _box.delete(key);
  }
}
