import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

  /// 从相册选择并导入图片（带进度显示）
  Future<List<MediaItem>> pickAndImportImages({int maxImages = 100}) async {
    // 防止重复导入
    if (_isImporting) {
      return [];
    }
    _isImporting = true;

    try {
      // 阶段1：选择图片（显示"正在加载图片"）
      _ref.read(importProgressProvider.notifier).state = ImportProgress.selecting;

      final xFiles = await _mediaService.pickImages(maxImages: maxImages);
      debugPrint('[Import] 选择的图片数量: ${xFiles.length}');
      for (int i = 0; i < xFiles.length; i++) {
        debugPrint('[Import] 图片[$i]: ${xFiles[i].path}');
      }
      
      if (xFiles.isEmpty) {
        _ref.read(importProgressProvider.notifier).state = ImportProgress.idle;
        return [];
      }

      // 去重：根据文件路径去重
      final uniquePaths = <String>{};
      final uniqueFiles = <XFile>[];
      for (final xFile in xFiles) {
        if (uniquePaths.add(xFile.path)) {
          uniqueFiles.add(xFile);
        }
      }

      final total = uniqueFiles.length;
      final List<MediaItem> importedItems = [];
      int completed = 0;

      // 阶段2：导入图片（显示进度）
      _ref.read(importProgressProvider.notifier).state = ImportProgress(
        total: total,
        completed: 0,
        stage: ImportStage.importing,
      );

      // 串行处理，避免并发问题
      for (final xFile in uniqueFiles) {
        final item = await _mediaService.importImage(xFile);
        if (item != null) {
          importedItems.add(item);
        }
        completed++;
        // 更新进度
        _ref.read(importProgressProvider.notifier).state = ImportProgress(
          total: total,
          completed: completed,
          stage: ImportStage.importing,
        );
      }

      if (importedItems.isNotEmpty) {
        await refresh();
      }
      return importedItems;
    } finally {
      // 导入完成，重置状态
      _ref.read(importProgressProvider.notifier).state = ImportProgress.idle;
      _isImporting = false;
    }
  }

  /// 导入单张图片
  Future<MediaItem?> importSingleImage(XFile xFile, {DateTime? takenDate}) async {
    final item = await _mediaService.importImage(xFile, takenDate: takenDate);
    if (item != null) {
      await refresh();
    }
    return item;
  }

  /// 拍照并导入
  Future<MediaItem?> takePhotoAndImport() async {
    final xFile = await _mediaService.takePhoto();
    if (xFile == null) return null;

    final item = await _mediaService.importImage(xFile);
    if (item != null) {
      await refresh();
    }
    return item;
  }

  /// 选择并导入视频
  Future<MediaItem?> pickAndImportVideo() async {
    final xFile = await _mediaService.pickVideo();
    if (xFile == null) return null;

    final item = await _mediaService.importVideo(xFile);
    if (item != null) {
      await refresh();
    }
    return item;
  }

  /// 录制并导入视频
  Future<MediaItem?> recordAndImportVideo() async {
    final xFile = await _mediaService.recordVideo();
    if (xFile == null) return null;

    final item = await _mediaService.importVideo(xFile);
    if (item != null) {
      await refresh();
    }
    return item;
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
