import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';
import '../services/database_service.dart';

/// 相册状态
class AlbumNotifier extends StateNotifier<AsyncValue<List<MediaItem>>> {
  final MediaService _mediaService = MediaService();

  AlbumNotifier() : super(const AsyncValue.loading()) {
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

  /// 从相册选择并导入图片
  Future<List<MediaItem>> pickAndImportImages({int maxImages = 9}) async {
    final xFiles = await _mediaService.pickImages(maxImages: maxImages);
    if (xFiles.isEmpty) return [];

    final items = await _mediaService.importImages(xFiles);
    if (items.isNotEmpty) {
      await refresh();
    }
    return items;
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
  return AlbumNotifier();
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
