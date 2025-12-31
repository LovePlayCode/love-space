import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';
import '../services/database_service.dart';

/// 导入进度状态
class ImportProgress {
  final int total;
  final int completed;
  final ImportStage stage;

  const ImportProgress({
    required this.total,
    required this.completed,
    required this.stage,
  });

  double get percentage => total > 0 ? completed / total : 0;

  static const idle = ImportProgress(total: 0, completed: 0, stage: ImportStage.idle);
  static const selecting = ImportProgress(total: 0, completed: 0, stage: ImportStage.selecting);
}

/// 导入阶段
enum ImportStage {
  idle,       // 空闲
  selecting,  // 正在选择图片（系统相册）
  importing,  // 正在导入
}

/// 导入进度 Provider
final importProgressProvider = StateProvider<ImportProgress>((ref) => ImportProgress.idle);

/// 相册状态
class AlbumNotifier extends StateNotifier<AsyncValue<List<MediaItem>>> {
  final MediaService _mediaService = MediaService();
  final Ref _ref;
  bool _isImporting = false; // 防止重复导入

  AlbumNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadMediaItems();
  }

  Future<void> _loadMediaItems() async {
    try {
      final items = await _mediaService.getAllMediaItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadMediaItems();
  }

  /// 导入选中的资源（支持图片/视频/Live Photo）
  Future<List<MediaItem>> importAssets(List<AssetEntity> assets) async {
    if (_isImporting || assets.isEmpty) {
      return [];
    }
    _isImporting = true;

    try {
      final total = assets.length;
      final List<MediaItem> importedItems = [];

      // 开始导入
      _ref.read(importProgressProvider.notifier).state = ImportProgress(
        total: total,
        completed: 0,
        stage: ImportStage.importing,
      );

      // 串行处理，避免并发问题
      for (int i = 0; i < assets.length; i++) {
        final asset = assets[i];
        debugPrint('[Import] 导入资源 ${i + 1}/$total: ${asset.id}, type=${asset.type}, isLivePhoto=${_mediaService.isLivePhoto(asset)}');

        final item = await _mediaService.importAsset(asset);
        if (item != null) {
          importedItems.add(item);
        }

        // 更新进度
        _ref.read(importProgressProvider.notifier).state = ImportProgress(
          total: total,
          completed: i + 1,
          stage: ImportStage.importing,
        );
      }

      if (importedItems.isNotEmpty) {
        await refresh();
      }

      debugPrint('[Import] 导入完成，成功 ${importedItems.length}/$total');
      return importedItems;
    } finally {
      _ref.read(importProgressProvider.notifier).state = ImportProgress.idle;
      _isImporting = false;
    }
  }

  /// 删除媒体项
  Future<bool> deleteItem(MediaItem item) async {
    final success = await _mediaService.deleteMediaItem(item);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// 更新备注
  Future<bool> updateCaption(int id, String caption) async {
    final success = await _mediaService.updateCaption(id, caption);
    if (success) {
      await refresh();
    }
    return success;
  }

  /// 获取指定日期的媒体
  Future<List<MediaItem>> getMediaByDate(DateTime date) async {
    return await _mediaService.getMediaItemsByDate(date);
  }
}

/// 相册 Provider
final albumProvider = StateNotifierProvider<AlbumNotifier, AsyncValue<List<MediaItem>>>((ref) {
  return AlbumNotifier(ref);
});

/// 媒体总数 Provider
final mediaCountProvider = FutureProvider<int>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getMediaCount();
});

/// 有媒体的日期集合 Provider
final mediaDatesProvider = FutureProvider<Set<String>>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getMediaDates();
});

/// 根据标签筛选的媒体 Provider
final filteredMediaProvider = Provider<AsyncValue<List<MediaItem>>>((ref) {
  final albumAsync = ref.watch(albumProvider);
  final selectedTags = ref.watch(selectedFilterTagsProvider);

  if (selectedTags.isEmpty) {
    return albumAsync;
  }

  return albumAsync.whenData((items) {
    // 这里需要异步获取，但 Provider 是同步的，所以使用另一种方式
    return items;
  });
});

/// 当前选中的筛选标签 Provider
final selectedFilterTagsProvider = StateProvider<Set<int>>((ref) => {});

/// 根据标签筛选媒体的 FutureProvider
final mediaByTagsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final selectedTags = ref.watch(selectedFilterTagsProvider);
  final dbService = DatabaseService();

  if (selectedTags.isEmpty) {
    return await dbService.getAllMediaItems();
  }

  return await dbService.getMediaItemsByTags(selectedTags.toList());
});
