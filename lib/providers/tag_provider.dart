import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

/// 标签列表状态
class TagNotifier extends StateNotifier<AsyncValue<List<Tag>>> {
  final DatabaseService _dbService = DatabaseService();

  TagNotifier() : super(const AsyncValue.loading()) {
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _dbService.getAllTags();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadTags();
  }

  /// 创建标签
  Future<Tag?> createTag(String name, {String? color, String? icon}) async {
    try {
      // 检查是否已存在
      final existing = await _dbService.getTagByName(name);
      if (existing != null) return existing;

      final tag = Tag(name: name, color: color, icon: icon);
      final id = await _dbService.insertTag(tag);
      final newTag = tag.copyWith(id: id);
      await refresh();
      return newTag;
    } catch (e) {
      return null;
    }
  }

  /// 更新标签
  Future<bool> updateTag(Tag tag) async {
    try {
      await _dbService.updateTag(tag);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除标签
  Future<bool> deleteTag(int tagId) async {
    try {
      await _dbService.deleteTag(tagId);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 标签列表 Provider
final tagProvider = StateNotifierProvider<TagNotifier, AsyncValue<List<Tag>>>((ref) {
  return TagNotifier();
});

/// 媒体标签 Provider - 获取指定媒体的标签
final mediaTagsProvider = FutureProvider.family<List<Tag>, int>((ref, mediaId) async {
  final dbService = DatabaseService();
  return await dbService.getTagsForMedia(mediaId);
});

/// 标签使用次数 Provider
final tagUsageCountProvider = FutureProvider.family<int, int>((ref, tagId) async {
  final dbService = DatabaseService();
  return await dbService.getTagUsageCount(tagId);
});
