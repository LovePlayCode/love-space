import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// 系统相册服务 - 直接读取系统相册，按时间倒序平铺展示
class SystemAlbumService {
  /// 单例模式
  static final SystemAlbumService _instance = SystemAlbumService._internal();
  factory SystemAlbumService() => _instance;
  SystemAlbumService._internal();

  /// 缓存的所有资源
  List<AssetEntity>? _cachedAssets;

  /// 上次刷新时间
  DateTime? _lastRefreshTime;

  /// 缓存有效期（5分钟）
  static const _cacheValidDuration = Duration(minutes: 5);

  /// 请求相册权限
  Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  /// 检查权限状态
  Future<bool> hasPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  /// 打开系统设置
  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  /// 获取所有照片（按时间倒序）
  Future<List<AssetEntity>> getAllPhotos({bool forceRefresh = false}) async {
    // 检查缓存是否有效
    if (!forceRefresh && _isCacheValid()) {
      return _cachedAssets!;
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    try {
      // 获取所有照片和视频
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
          videoOption: const FilterOption(
            durationConstraint: DurationConstraint(
              max: Duration(minutes: 30),
            ),
          ),
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      if (albums.isEmpty) return [];

      // 获取"最近项目"相册（包含所有照片）
      final recentAlbum = albums.first;
      final totalCount = await recentAlbum.assetCountAsync;

      // 分批加载所有资源
      final allAssets = <AssetEntity>[];
      const pageSize = 500;
      int page = 0;

      while (allAssets.length < totalCount) {
        final assets = await recentAlbum.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        if (assets.isEmpty) break;
        allAssets.addAll(assets);
        page++;
      }

      // 更新缓存
      _cachedAssets = allAssets;
      _lastRefreshTime = DateTime.now();

      return allAssets;
    } catch (e) {
      debugPrint('[SystemAlbumService] 获取照片失败: $e');
      return [];
    }
  }

  /// 获取照片总数
  Future<int> getTotalCount() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return 0;

    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      if (albums.isEmpty) return 0;
      return await albums.first.assetCountAsync;
    } catch (e) {
      debugPrint('[SystemAlbumService] 获取照片数量失败: $e');
      return 0;
    }
  }

  /// 分页获取照片（用于懒加载）
  Future<List<AssetEntity>> getAssetsPaged({
    required int page,
    int pageSize = 50,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      if (albums.isEmpty) return [];

      final recentAlbum = albums.first;
      return await recentAlbum.getAssetListPaged(page: page, size: pageSize);
    } catch (e) {
      debugPrint('[SystemAlbumService] 分页获取照片失败: $e');
      return [];
    }
  }

  /// 检查是否为 Live Photo
  bool isLivePhoto(AssetEntity asset) {
    if (!Platform.isIOS) return false;
    return asset.type == AssetType.image && (asset.subtype & 8) != 0;
  }

  /// 获取资源的缩略图
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
    int quality = 80,
  }) async {
    try {
      return await asset.thumbnailDataWithSize(
        ThumbnailSize(width, height),
        quality: quality,
      );
    } catch (e) {
      debugPrint('[SystemAlbumService] 获取缩略图失败: $e');
      return null;
    }
  }

  /// 获取原始文件
  Future<File?> getOriginFile(AssetEntity asset) async {
    try {
      return await asset.originFile;
    } catch (e) {
      debugPrint('[SystemAlbumService] 获取原始文件失败: $e');
      return null;
    }
  }

  /// 获取 Live Photo 的视频文件
  Future<File?> getLivePhotoVideo(AssetEntity asset) async {
    if (!isLivePhoto(asset)) return null;

    try {
      final file = await asset.originFileWithSubtype;
      return file;
    } catch (e) {
      debugPrint('[SystemAlbumService] 获取 Live Photo 视频失败: $e');
      return null;
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedAssets = null;
    _lastRefreshTime = null;
  }

  /// 检查缓存是否有效
  bool _isCacheValid() {
    if (_cachedAssets == null || _lastRefreshTime == null) return false;
    return DateTime.now().difference(_lastRefreshTime!) < _cacheValidDuration;
  }
}
