import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/tag_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/media_item.dart';
import '../../models/tag.dart';
import '../../providers/album_provider.dart';
import '../../providers/tag_provider.dart';
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
  bool _isProgressDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // 在框架渲染完成后执行监听逻辑，监听importProgressProvider的状态变化。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 监听导入进度状态的变化
      ref.listenManual(importProgressProvider, (previous, next) {
        final shouldShow = next.stage != ImportStage.idle;
        if (shouldShow && !_isProgressDialogShowing) {
          _showImportProgressDialog();
        } else if (!shouldShow && _isProgressDialogShowing) {
          _dismissProgressDialog();
        }
      });
    });
  }

  void _showImportProgressDialog() {
    if (_isProgressDialogShowing || !mounted) return;
    _isProgressDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _ImportProgressDialog(),
    ).then((_) {
      _isProgressDialogShowing = false;
    });
  }

  void _dismissProgressDialog() {
    if (_isProgressDialogShowing && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isProgressDialogShowing = false;
    }
  }

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
    final selectedTags = ref.watch(selectedFilterTagsProvider);
    final tagsAsync = ref.watch(tagProvider);

    // 根据是否有筛选标签选择数据源
    final mediaAsync = selectedTags.isEmpty
        ? ref.watch(albumProvider)
        : ref.watch(mediaByTagsProvider);

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
                mediaAsync.whenOrNull(
                      data: (items) => TextButton(
                        onPressed: () => _selectAll(items),
                        child: const Text('全选'),
                      ),
                    ) ??
                    const SizedBox(),
                IconButton(
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                  icon: Icon(
                    Icons.delete_rounded,
                    color: _selectedIds.isEmpty
                        ? AppColors.textHint
                        : AppColors.error,
                  ),
                ),
              ]
            : [
                IconButton(
                  onPressed: () => _showTagFilterSheet(context, ref),
                  icon: Badge(
                    isLabelVisible: selectedTags.isNotEmpty,
                    label: Text('${selectedTags.length}'),
                    child: const Icon(Icons.filter_list_rounded),
                  ),
                ),
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
      body: Column(
        children: [
          // 标签筛选栏
          if (selectedTags.isNotEmpty)
            _buildSelectedTagsBar(tagsAsync, selectedTags),
          // 媒体列表
          Expanded(
            child: mediaAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => AppErrorWidget(
                message: '加载失败',
                onRetry: () {
                  ref.invalidate(albumProvider);
                  ref.invalidate(mediaByTagsProvider);
                },
              ),
              data: (mediaItems) {
                if (mediaItems.isEmpty) {
                  if (selectedTags.isNotEmpty) {
                    return _buildNoFilterResultState(context, ref);
                  }
                  return _buildEmptyState(context, ref);
                }
                return _buildWaterfallGrid(context, ref, mediaItems);
              },
            ),
          ),
        ],
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

  Widget _buildSelectedTagsBar(
    AsyncValue<List<Tag>> tagsAsync,
    Set<int> selectedTags,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: tagsAsync.whenOrNull(
                data: (tags) => Row(
                  children: tags
                      .where((t) => selectedTags.contains(t.id))
                      .map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              tag.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              final newSet = Set<int>.from(selectedTags)
                                ..remove(tag.id);
                              ref
                                      .read(selectedFilterTagsProvider.notifier)
                                      .state =
                                  newSet;
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(selectedFilterTagsProvider.notifier).state = {};
            },
            child: const Text('清除', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '没有符合筛选条件的照片',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(selectedFilterTagsProvider.notifier).state = {};
            },
            child: const Text('清除筛选'),
          ),
        ],
      ),
    );
  }

  void _showTagFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) =>
            _TagFilterSheet(scrollController: scrollController),
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

  Widget _buildWaterfallGrid(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> items,
  ) {
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
                const Text('添加照片/视频', style: AppTextStyles.subtitle1),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
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
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
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
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
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
                    child: const Icon(
                      Icons.video_camera_back_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
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
    // 视频使用封面，图片使用原图
    final file = File(item.displayPath);
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

/// 导入进度对话框
class _ImportProgressDialog extends ConsumerWidget {
  const _ImportProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(importProgressProvider);

    final isSelecting = progress.stage == ImportStage.selecting;
    final isImporting = progress.stage == ImportStage.importing;

    String title;
    String subtitle;

    if (isSelecting) {
      title = '正在加载图片...';
      subtitle = '请稍候，系统正在处理选中的图片';
    } else if (isImporting) {
      title = '正在导入 ${progress.completed}/${progress.total}';
      subtitle = '${(progress.percentage * 100).toInt()}% 完成';
    } else {
      title = '准备中...';
      subtitle = '请稍候';
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: isImporting && progress.total > 0
                      ? progress.percentage
                      : null,
                  strokeWidth: 4,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
                if (isImporting && progress.total > 0)
                  Text(
                    '${(progress.percentage * 100).toInt()}%',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.body1),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 标签筛选 Sheet
class _TagFilterSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _TagFilterSheet({required this.scrollController});

  @override
  ConsumerState<_TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends ConsumerState<_TagFilterSheet> {
  final _newTagController = TextEditingController();

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagProvider);
    final selectedTags = ref.watch(selectedFilterTagsProvider);

    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('标签筛选', style: AppTextStyles.subtitle1),
                  TextButton.icon(
                    onPressed: () => _showCreateTagDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建标签'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 标签列表
        Expanded(
          child: tagsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('加载失败: $e')),
            data: (tags) {
              if (tags.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.label_off_rounded,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '还没有标签',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showCreateTagDialog(context),
                        child: const Text('创建第一个标签'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = selectedTags.contains(tag.id);
                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getTagColor(tag.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TagIcons.getIcon(tag.icon) ?? Icons.label_rounded,
                        color: _getTagColor(tag.color),
                        size: 18,
                      ),
                    ),
                    title: Text(tag.name),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        final newSet = Set<int>.from(selectedTags);
                        if (value == true) {
                          newSet.add(tag.id!);
                        } else {
                          newSet.remove(tag.id);
                        }
                        ref.read(selectedFilterTagsProvider.notifier).state =
                            newSet;
                      },
                    ),
                    onTap: () {
                      final newSet = Set<int>.from(selectedTags);
                      if (isSelected) {
                        newSet.remove(tag.id);
                      } else {
                        newSet.add(tag.id!);
                      }
                      ref.read(selectedFilterTagsProvider.notifier).state =
                          newSet;
                    },
                    onLongPress: () => _showTagOptionsDialog(context, tag),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getTagColor(String? colorHex) {
    if (colorHex == null) return AppColors.primary;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  void _showCreateTagDialog(BuildContext context) {
    _newTagController.clear();
    String? selectedIcon;
    String? selectedColor;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建标签'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _newTagController,
                  decoration: const InputDecoration(
                    hintText: '输入标签名称',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('选择图标', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildIconSelector(
                  selectedIcon: selectedIcon,
                  selectedColor: selectedColor,
                  onIconSelected: (icon) {
                    setDialogState(() => selectedIcon = icon);
                  },
                ),
                const SizedBox(height: 16),
                const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildColorSelector(
                  selectedColor: selectedColor,
                  onColorSelected: (color) {
                    setDialogState(() => selectedColor = color);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = _newTagController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(tagProvider.notifier).createTag(
                    name,
                    color: selectedColor,
                    icon: selectedIcon,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector({
    String? selectedIcon,
    String? selectedColor,
    required Function(String?) onIconSelected,
  }) {
    final color = _getTagColor(selectedColor);
    final iconCodes = TagIcons.allIconCodes;
    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: iconCodes.map((iconCode) {
            final icon = TagIcons.getIcon(iconCode);
            final isSelected = selectedIcon == iconCode;
            return GestureDetector(
              onTap: () => onIconSelected(iconCode),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    String? selectedColor,
    required Function(String?) onColorSelected,
  }) {
    const colors = [
      '#FF5722', // 深橙
      '#E91E63', // 粉红
      '#9C27B0', // 紫色
      '#673AB7', // 深紫
      '#3F51B5', // 靛蓝
      '#2196F3', // 蓝色
      '#00BCD4', // 青色
      '#009688', // 蓝绿
      '#4CAF50', // 绿色
      '#8BC34A', // 浅绿
      '#FF9800', // 橙色
      '#795548', // 棕色
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((colorHex) {
        final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        final isSelected = selectedColor == colorHex;
        return GestureDetector(
          onTap: () => onColorSelected(colorHex),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _showTagOptionsDialog(BuildContext context, Tag tag) {
    final outerContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tag.name),
        content: const Text('选择操作'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showEditTagDialog(outerContext, tag);
            },
            child: const Text('编辑'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final confirmed = await showDialog<bool>(
                context: outerContext,
                builder: (confirmContext) => AlertDialog(
                  title: const Text('确认删除'),
                  content: Text('确定要删除标签"${tag.name}"吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(confirmContext, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(confirmContext, true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(tagProvider.notifier).deleteTag(tag.id!);
                // 从筛选中移除
                final selectedTags = ref.read(selectedFilterTagsProvider);
                if (selectedTags.contains(tag.id)) {
                  ref
                      .read(selectedFilterTagsProvider.notifier)
                      .state = Set<int>.from(selectedTags)
                    ..remove(tag.id);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEditTagDialog(BuildContext context, Tag tag) {
    _newTagController.text = tag.name;
    String? selectedIcon = tag.icon;
    String? selectedColor = tag.color;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑标签'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _newTagController,
                  decoration: const InputDecoration(
                    hintText: '输入标签名称',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('选择图标', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildIconSelector(
                  selectedIcon: selectedIcon,
                  selectedColor: selectedColor,
                  onIconSelected: (icon) {
                    setDialogState(() => selectedIcon = icon);
                  },
                ),
                const SizedBox(height: 16),
                const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildColorSelector(
                  selectedColor: selectedColor,
                  onColorSelected: (color) {
                    setDialogState(() => selectedColor = color);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = _newTagController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(tagProvider.notifier).updateTag(
                    tag.copyWith(
                      name: name,
                      color: selectedColor,
                      icon: selectedIcon,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
