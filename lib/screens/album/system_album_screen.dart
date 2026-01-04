import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/system_album_provider.dart';
import '../../services/system_album_service.dart';
import '../../widgets/common/loading_widget.dart';

/// 系统相册页面 - 直接读取系统相册，按时间倒序平铺展示
class SystemAlbumScreen extends ConsumerStatefulWidget {
  const SystemAlbumScreen({super.key});

  @override
  ConsumerState<SystemAlbumScreen> createState() => _SystemAlbumScreenState();
}

class _SystemAlbumScreenState extends ConsumerState<SystemAlbumScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(allPhotosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('时光相册'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: () => ref.read(allPhotosProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: photosAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => _buildErrorState(error),
        data: (photos) {
          if (photos.isEmpty) {
            return _buildEmptyState();
          }
          return _buildPhotoGrid(photos);
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final isPermissionError = error.toString().contains('permission');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermissionError ? Icons.photo_library_outlined : Icons.error_outline_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isPermissionError ? '需要相册访问权限' : '加载失败',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: 8),
            Text(
              isPermissionError ? '请在设置中允许访问相册' : '请稍后重试',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isPermissionError)
              ElevatedButton(
                onPressed: () => SystemAlbumService().openSettings(),
                child: const Text('打开设置'),
              )
            else
              ElevatedButton(
                onPressed: () => ref.read(allPhotosProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              '相册是空的',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: 8),
            Text(
              '去拍摄一些美好的瞬间吧',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<AssetEntity> photos) {
    return RefreshIndicator(
      onRefresh: () => ref.read(allPhotosProvider.notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MasonryGridView.count(
          controller: _scrollController,
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return _PhotoTile(
              asset: photos[index],
              onTap: () => _openPhotoDetail(photos[index]),
            );
          },
        ),
      ),
    );
  }

  void _openPhotoDetail(AssetEntity asset) {
    // 对 ID 进行 URL 编码，因为 AssetEntity.id 可能包含斜杠
    final encodedId = Uri.encodeComponent(asset.id);
    context.push('/album/photo/$encodedId');
  }
}

/// 照片缩略图组件
class _PhotoTile extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.asset,
    required this.onTap,
  });

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final data = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(300, 300),
        quality: 80,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算宽高比
    final aspectRatio = widget.asset.width > 0 && widget.asset.height > 0
        ? widget.asset.width / widget.asset.height
        : 1.0;
    final clampedRatio = aspectRatio.clamp(0.5, 2.0);

    return GestureDetector(
      onTap: widget.onTap,
      child: AspectRatio(
        aspectRatio: clampedRatio,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPink,
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 缩略图
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_thumbnailData != null)
                Image.memory(
                  _thumbnailData!,
                  fit: BoxFit.cover,
                )
              else
                const Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.textHint),
                ),
              // 视频标识
              if (widget.asset.type == AssetType.video)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatDuration(widget.asset.videoDuration),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              // Live Photo 标识
              if (_isLivePhoto(widget.asset))
                const Positioned(
                  top: 4,
                  left: 4,
                  child: Icon(
                    Icons.motion_photos_on_rounded,
                    color: Colors.white,
                    size: 16,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLivePhoto(AssetEntity asset) {
    return asset.type == AssetType.image && (asset.subtype & 8) != 0;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
