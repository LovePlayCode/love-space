import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/media_item.dart';
import '../../providers/album_provider.dart';
import '../../widgets/common/loading_widget.dart';
import 'package:intl/intl.dart';

class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('时光相册'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: () => _showAddOptions(context, ref),
            icon: const Icon(Icons.add_photo_alternate_rounded),
          ),
        ],
      ),
      body: albumAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: '加载失败',
          onRetry: () => ref.refresh(albumProvider),
        ),
        data: (mediaItems) {
          if (mediaItems.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildWaterfallGrid(context, ref, mediaItems);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return EmptyWidget(
      icon: Icons.photo_library_rounded,
      title: '还没有照片',
      subtitle: '点击下方按钮添加你们的第一张照片吧',
      action: ElevatedButton.icon(
        onPressed: () => _showAddOptions(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加照片'),
      ),
    );
  }

  Widget _buildWaterfallGrid(BuildContext context, WidgetRef ref, List<MediaItem> items) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MediaCard(
            item: item,
            onTap: () => context.push('/album/photo/${item.id}'),
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '添加照片/视频',
                style: AppTextStyles.subtitle1,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('从相册选择照片'),
                subtitle: const Text('选择多张照片'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(ref);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                ),
                title: const Text('从相册选择视频'),
                subtitle: const Text('选择一个视频'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ref);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('拍照'),
                subtitle: const Text('立即拍摄一张'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(ref);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.video_camera_back_rounded, color: AppColors.primary),
                ),
                title: const Text('录制视频'),
                subtitle: const Text('立即录制一段'),
                onTap: () {
                  Navigator.pop(context);
                  _recordVideo(ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(WidgetRef ref) async {
    await ref.read(albumProvider.notifier).pickAndImportImages();
  }

  Future<void> _takePhoto(WidgetRef ref) async {
    await ref.read(albumProvider.notifier).takePhotoAndImport();
  }

  Future<void> _pickVideo(WidgetRef ref) async {
    await ref.read(albumProvider.notifier).pickAndImportVideo();
  }

  Future<void> _recordVideo(WidgetRef ref) async {
    await ref.read(albumProvider.notifier).recordAndImportVideo();
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const _MediaCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 计算卡片高度，基于图片宽高比
    final aspectRatio = item.aspectRatio;
    final cardWidth = (MediaQuery.of(context).size.width - 36) / 2;
    final imageHeight = cardWidth / aspectRatio;
    final clampedHeight = imageHeight.clamp(120.0, 300.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 图片/视频缩略图
              SizedBox(
                width: double.infinity,
                height: clampedHeight,
                child: _buildImage(),
              ),
              // 视频播放按钮（居中）
              if (item.isVideo)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              // 视频标识（右上角）
              if (item.isVideo)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '视频',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              // 日期和备注
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.caption != null && item.caption!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            item.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        DateFormat('yyyy/MM/dd').format(item.takenDateTime),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final file = File(item.localPath);
    if (!file.existsSync()) {
      return Container(
        color: AppColors.backgroundPink,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textHint),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.backgroundPink,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textHint),
        ),
      ),
    );
  }
}
