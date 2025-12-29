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
import '../../widgets/common/toast_utils.dart';
import 'package:intl/intl.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<MediaItem> items) {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(items.where((e) => e.id != null).map((e) => e.id!));
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 项吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final albumNotifier = ref.read(albumProvider.notifier);
    final currentItems = ref.read(albumProvider).valueOrNull ?? [];
    
    int successCount = 0;
    for (final id in _selectedIds) {
      final item = currentItems.firstWhere(
        (e) => e.id == id,
        orElse: () => currentItems.first,
      );
      if (item.id == id) {
        final success = await albumNotifier.deleteItem(item);
        if (success) successCount++;
      }
    }

    if (mounted) {
      ToastUtils.showSuccess(context, '已删除 $successCount 项');
      _toggleSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumAsync = ref.watch(albumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('已选择 ${_selectedIds.length} 项')
            : const Text('时光相册'),
        backgroundColor: AppColors.background,
        leading: _isSelectionMode
            ? IconButton(
                onPressed: _toggleSelectionMode,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        actions: _isSelectionMode
            ? [
                albumAsync.whenOrNull(
                  data: (items) => TextButton(
                    onPressed: () => _selectAll(items),
                    child: const Text('全选'),
                  ),
                ) ?? const SizedBox(),
                IconButton(
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                  icon: Icon(
                    Icons.delete_rounded,
                    color: _selectedIds.isEmpty ? AppColors.textHint : AppColors.error,
                  ),
                ),
              ]
            : [
                IconButton(
                  onPressed: () => _toggleSelectionMode(),
                  icon: const Icon(Icons.checklist_rounded),
                ),
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
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
          final itemId = item.id;
          final isSelected = itemId != null && _selectedIds.contains(itemId);
          return _MediaCard(
            item: item,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onTap: () {
              if (_isSelectionMode) {
                if (itemId != null) _toggleSelection(itemId);
              } else {
                context.push('/album/photo/${item.id}');
              }
            },
            onLongPress: () {
              if (!_isSelectionMode && itemId != null) {
                _toggleSelectionMode();
                _toggleSelection(itemId);
              }
            },
          );
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SingleChildScrollView(
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
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 22),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_camera_back_rounded, color: AppColors.primary, size: 22),
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
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const _MediaCard({
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
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
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 13 : 16),
          child: Stack(
            children: [
              // 图片/视频缩略图
              SizedBox(
                width: double.infinity,
                height: clampedHeight,
                child: _buildImage(),
              ),
              // 选择模式下的勾选框
              if (isSelectionMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
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
