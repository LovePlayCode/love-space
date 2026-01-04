import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/system_album_service.dart';

/// 系统相册服务 Provider
final systemAlbumServiceProvider = Provider((ref) => SystemAlbumService());

/// 相册权限状态 Provider
final albumPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(systemAlbumServiceProvider);
  return await service.hasPermission();
});

/// 所有照片 Provider（按时间倒序平铺展示）
final allPhotosProvider = StateNotifierProvider<AllPhotosNotifier, AsyncValue<List<AssetEntity>>>((ref) {
  return AllPhotosNotifier(ref.watch(systemAlbumServiceProvider));
});

/// 照片列表状态管理器
class AllPhotosNotifier extends StateNotifier<AsyncValue<List<AssetEntity>>> {
  final SystemAlbumService _service;

  AllPhotosNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPhotos();
  }

  /// 加载照片
  Future<void> loadPhotos() async {
    try {
      state = const AsyncValue.loading();
      final photos = await _service.getAllPhotos();
      state = AsyncValue.data(photos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final photos = await _service.getAllPhotos(forceRefresh: true);
      state = AsyncValue.data(photos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 照片总数 Provider
final photoCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(systemAlbumServiceProvider);
  return await service.getTotalCount();
});

/// 分页加载照片 Provider（用于懒加载场景）
final pagedPhotosProvider = FutureProvider.family<List<AssetEntity>, int>((ref, page) async {
  final service = ref.watch(systemAlbumServiceProvider);
  return await service.getAssetsPaged(page: page, pageSize: 50);
});
