import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/constants/tag_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/tag.dart';
import '../../providers/system_album_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/database_service.dart';
import '../../services/system_album_service.dart';
import '../../widgets/common/loading_widget.dart';

/// 系统相册选中的标签筛选 Provider
final selectedSystemTagsProvider = StateProvider<Set<int>>((ref) => {});

/// 系统相册页面 - 直接读取系统相册，按时间倒序平铺展示
class SystemAlbumScreen extends ConsumerStatefulWidget {
  const SystemAlbumScreen({super.key});

  @override
  ConsumerState<SystemAlbumScreen> createState() => _SystemAlbumScreenState();
}

class _SystemAlbumScreenState extends ConsumerState<SystemAlbumScreen> {
  final ScrollController _scrollController = ScrollController();
  Set<String> _taggedAssetIds = {};

  @override
  void initState() {
    super.initState();
    _loadTaggedAssetIds();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTaggedAssetIds() async {
    final selectedTags = ref.read(selectedSystemTagsProvider);
    if (selectedTags.isEmpty) {
      setState(() => _taggedAssetIds = {});
      return;
    }
    
    final dbService = DatabaseService();
    final assetIds = await dbService.getAssetIdsByTags(selectedTags.toList());
    setState(() {
      _taggedAssetIds = assetIds.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(allPhotosProvider);
    final selectedTags = ref.watch(selectedSystemTagsProvider);
    final tagsAsync = ref.watch(tagProvider);

    // 监听标签变化
    ref.listen(selectedSystemTagsProvider, (previous, next) {
      _loadTaggedAssetIds();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('时光相册'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: () => _showTagFilterSheet(context),
            icon: Badge(
              isLabelVisible: selectedTags.isNotEmpty,
              label: Text('${selectedTags.length}'),
              child: const Icon(Icons.filter_list_rounded),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(allPhotosProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签筛选条
          if (selectedTags.isNotEmpty)
            tagsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (allTags) => _buildSelectedTagsBar(allTags, selectedTags),
            ),
          // 照片网格
          Expanded(
            child: photosAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => _buildErrorState(error),
              data: (photos) {
                // 根据标签筛选
                final filteredPhotos = selectedTags.isEmpty
                    ? photos
                    : photos.where((p) => _taggedAssetIds.contains(p.id)).toList();
                
                if (filteredPhotos.isEmpty) {
                  return selectedTags.isEmpty 
                      ? _buildEmptyState() 
                      : _buildNoFilterResultState();
                }
                return _buildPhotoGrid(filteredPhotos);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTagsBar(List<Tag> allTags, Set<int> selectedTagIds) {
    final selectedTagsList = allTags.where((t) => selectedTagIds.contains(t.id)).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedTagsList.map((tag) {
                  final color = _getTagColor(tag.color);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: Icon(
                        TagIcons.getIcon(tag.icon) ?? Icons.label_rounded,
                        size: 16,
                        color: color,
                      ),
                      label: Text(tag.name, style: TextStyle(color: color, fontSize: 12)),
                      backgroundColor: color.withValues(alpha: 0.1),
                      side: BorderSide(color: color.withValues(alpha: 0.3)),
                      deleteIcon: Icon(Icons.close, size: 16, color: color),
                      onDeleted: () {
                        final newSet = Set<int>.from(selectedTagIds)..remove(tag.id);
                        ref.read(selectedSystemTagsProvider.notifier).state = newSet;
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(selectedSystemTagsProvider.notifier).state = {};
            },
            child: const Text('清除', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
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

  Widget _buildNoFilterResultState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text('没有符合筛选条件的照片', style: AppTextStyles.subtitle1),
            const SizedBox(height: 8),
            Text(
              '试试选择其他标签',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(selectedSystemTagsProvider.notifier).state = {};
              },
              child: const Text('清除筛选'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagFilterSheet(BuildContext context) {
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
        builder: (context, scrollController) => _TagFilterSheet(
          scrollController: scrollController,
        ),
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
              isPermissionError
                  ? Icons.photo_library_outlined
                  : Icons.error_outline_rounded,
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
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
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
            Text('相册是空的', style: AppTextStyles.subtitle1),
            const SizedBox(height: 8),
            Text(
              '去拍摄一些美好的瞬间吧',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
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
          crossAxisCount: 2,
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

  const _PhotoTile({required this.asset, required this.onTap});

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
                Image.memory(_thumbnailData!, fit: BoxFit.cover)
              else
                const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.textHint,
                  ),
                ),
              // 视频标识
              if (widget.asset.type == AssetType.video)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
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

/// 标签筛选 Sheet
class _TagFilterSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _TagFilterSheet({required this.scrollController});

  @override
  ConsumerState<_TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends ConsumerState<_TagFilterSheet> {
  late Set<int> _tempSelectedTags;

  @override
  void initState() {
    super.initState();
    _tempSelectedTags = Set.from(ref.read(selectedSystemTagsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagProvider);

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
                  const Text('按标签筛选', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      if (_tempSelectedTags.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() => _tempSelectedTags.clear());
                          },
                          child: const Text('清除'),
                        ),
                      TextButton(
                        onPressed: () {
                          ref.read(selectedSystemTagsProvider.notifier).state = _tempSelectedTags;
                          Navigator.pop(context);
                        },
                        child: const Text('确定'),
                      ),
                    ],
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
                      Icon(Icons.label_off_rounded, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('还没有标签', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        '在照片详情页可以添加标签',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
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
                  final isSelected = _tempSelectedTags.contains(tag.id);
                  final color = _getTagColor(tag.color);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _tempSelectedTags.add(tag.id!);
                        } else {
                          _tempSelectedTags.remove(tag.id);
                        }
                      });
                    },
                    title: Text(tag.name),
                    secondary: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TagIcons.getIcon(tag.icon) ?? Icons.label_rounded,
                        color: color,
                        size: 18,
                      ),
                    ),
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
}
