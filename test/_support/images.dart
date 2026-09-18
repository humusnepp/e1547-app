import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache manager that never yields an image.
///
/// Post widgets read a [BaseCacheManager] from the tree, and the real one wants
/// a plugin backed directory to write to. Every image drawn under this one
/// falls back to its error widget instead.
class NoImageCacheManager implements BaseCacheManager {
  const NoImageCacheManager();

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool? withProgress,
  }) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} holds no image');
}
