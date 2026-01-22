import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../models/daily_log.dart';
import '../../providers/calendar_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/common/toast_utils.dart';

class DailyDetailScreen extends ConsumerStatefulWidget {
  final String dateStr;

  const DailyDetailScreen({super.key, required this.dateStr});

  @override
  ConsumerState<DailyDetailScreen> createState() => _DailyDetailScreenState();
}

class _DailyDetailScreenState extends ConsumerState<DailyDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedMood;

  // 心情选项
  static const List<Map<String, String>> _moodOptions = [
    {'emoji': '🥰', 'label': '开心'},
    {'emoji': '😍', 'label': '恩爱'},
    {'emoji': '😐', 'label': '一般'},
    {'emoji': '😢', 'label': '难过'},
    {'emoji': '😡', 'label': '生气'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadExistingLog();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _loadExistingLog() {
    final log = ref.read(dateLogProvider(widget.dateStr));
    if (log != null) {
      _titleController.text = log.title ?? '';
      _contentController.text = log.content ?? '';
      _selectedMood = log.mood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.dateStr);
    final dateMediaAsync = ref.watch(dateMediaProvider(date));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 背景装饰 - 渐变光斑
          Positioned.fill(child: _buildBackgroundBlobs()),
          // 主内容
          SafeArea(
            top: false,
            child: Column(
              children: [
                // 固定顶部导航栏
                _buildHeader(context),
                // 可滚动内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 160),
                    child: Column(
                      children: [
                        // 日期选择器
                        _buildDatePicker(date),
                        // 标题输入
                        _buildTitleInput(),
                        // 心情选择
                        _buildMoodSelector(),
                        // 日记内容
                        _buildDiaryEditor(),
                        // 添加回忆（照片）
                        _buildPhotosSection(dateMediaAsync),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 底部保存按钮
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // 右上角绿色光斑
          Positioned(
            top: -128,
            right: -128,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
          ),
          // 左侧粉色光斑
          Positioned(
            top: 80,
            left: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          // 右下角橙色光斑
          Positioned(
            bottom: -80,
            right: 0,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 关闭按钮
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
            ),
          ),
          // 标题
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '记录今日时光',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
            ],
          ),
          // 占位
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDatePicker(DateTime date) {
    final dateStr = DateFormat('yyyy年 M月 d日', 'zh_CN').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Washi tape 装饰
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.rotate(
                  angle: -0.02,
                  child: Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // 日期卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: AppColors.cuteShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textHint,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: AppColors.cuteShadow,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Icon(
                Icons.title_rounded,
                color: AppColors.primary.withValues(alpha: 0.4),
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _titleController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '给今天起个标题吧...',
                  hintStyle: TextStyle(
                    color: AppColors.textHint.withValues(alpha: 0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.edit_rounded,
                color: AppColors.success.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.sentiment_satisfied_alt_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '今日心情',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 心情选项
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moodOptions.map((mood) {
              final isSelected = _selectedMood == mood['emoji'];
              return Expanded(
                child: _buildMoodItem(
                  emoji: mood['emoji']!,
                  label: mood['label']!,
                  isSelected: isSelected,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodItem({
    required String emoji,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = isSelected ? null : emoji;
        });
      },
      child: Column(
        children: [
          // Emoji 容器
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 选中时的脉冲动画背景
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 56 : 48,
                height: isSelected ? 56 : 48,
                transform: isSelected
                    ? (Matrix4.identity()..translate(0.0, -8.0))
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.backgroundWhite,
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.5,
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: isSelected ? 28 : 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 标签
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 右上角胶带
          Positioned(
            top: -12,
            right: -8,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 左下角胶带
          Positioned(
            bottom: -8,
            left: -8,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 64,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 日记本主体
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cuteShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧装订孔
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 16, bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundPink,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // 编辑区域 - 横线纸效果
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: CustomPaint(
                      painter: _LinedPaperPainter(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                        constraints: const BoxConstraints(minHeight: 260),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          minLines: 8,
                          decoration: InputDecoration(
                            hintText: '今天发生了什么有趣的事？写下来吧...',
                            hintStyle: TextStyle(
                              color: AppColors.textHint.withValues(alpha: 0.5),
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.88, // 约32px行高
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(AsyncValue<List<AssetEntity>> mediaAsync) {
    return mediaAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (mediaItems) {
        final photoCount = mediaItems.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '添加回忆',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$photoCount / 9',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 照片列表
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
                  itemCount: mediaItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddPhotoButton();
                    }
                    final asset = mediaItems[index - 1];
                    final rotation = (index % 2 == 0) ? -0.035 : 0.026;
                    return _buildPhotoItem(asset, rotation);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: () async {
        final result = await context.push<List<AssetEntity>>('/media-picker');
        if (result != null && result.isNotEmpty && mounted) {
          // 将选中的照片关联到当前日期
          final dbService = DatabaseService();
          final assetIds = result.map((e) => e.id).toList();
          await dbService.addAssetsToDate(widget.dateStr, assetIds);

          // 刷新页面以显示新添加的照片
          ref.invalidate(dateMediaProvider(DateTime.parse(widget.dateStr)));

          if (mounted) {
            ToastUtils.showSuccess(context, '已添加 ${result.length} 张照片');
          }
        }
      },
      child: Container(
        width: 96,
        height: 96,
        margin: const EdgeInsets.only(right: 16),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.primary.withValues(alpha: 0.3),
            strokeWidth: 2,
            radius: 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundPink.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  color: AppColors.primary.withValues(alpha: 0.4),
                  size: 30,
                ),
                const SizedBox(height: 4),
                Text(
                  '添加照片',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(AssetEntity asset, double rotation) {
    final tapeColor = rotation > 0
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.success.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Transform.rotate(
        angle: rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Washi tape
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.rotate(
                  angle: rotation > 0 ? 0.035 : -0.02,
                  child: Container(
                    width: 32,
                    height: 12,
                    decoration: BoxDecoration(
                      color: tapeColor,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 照片容器
            Container(
              width: 112,
              height: 96,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                boxShadow: AppColors.cuteShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _PhotoThumbnail(
                  asset: asset,
                  dateStr: widget.dateStr,
                  onTap: () => context.push('/album/photo/${asset.id}'),
                  onDelete: () => _removePhoto(asset),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto(AssetEntity asset) async {
    final dbService = DatabaseService();
    await dbService.removeAssetFromDate(widget.dateStr, asset.id);
    ref.invalidate(dateMediaProvider(DateTime.parse(widget.dateStr)));
    if (mounted) {
      ToastUtils.showSuccess(context, '已移除照片');
    }
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          48,
          24,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.95),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: GestureDetector(
            onTap: _saveLog,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    '保存美好时光',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLog() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _selectedMood == null) {
      // 如果标题、内容和心情都为空，删除日记
      await ref.read(dailyLogProvider.notifier).deleteLog(widget.dateStr);
    } else {
      final log = DailyLog(
        dateStr: widget.dateStr,
        title: title.isEmpty ? null : title,
        content: content.isEmpty ? null : content,
        mood: _selectedMood,
      );
      await ref.read(dailyLogProvider.notifier).saveLog(log);
    }

    if (mounted) {
      ToastUtils.showSuccess(context, '保存成功');
      context.pop();
    }
  }
}

/// 照片缩略图组件（带删除按钮）
class _PhotoThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final String dateStr;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoThumbnail({
    required this.asset,
    required this.dateStr,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<_PhotoThumbnail> {
  Uint8List? _thumbnailData;
  bool _showDelete = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 80,
    );
    if (mounted) {
      setState(() => _thumbnailData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        setState(() => _showDelete = true);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 缩略图
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundPink,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _thumbnailData != null
                ? Image.memory(
                    _thumbnailData!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
          // 删除按钮
          if (_showDelete)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  widget.onDelete();
                  setState(() => _showDelete = false);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 横线纸背景绘制器
class _LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const lineHeight = 32.0; // 行高
    const startY = 16.0; // 从 padding 开始

    double y = startY + lineHeight;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 虚线边框绘制器
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.radius = 16,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    // 绘制虚线
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = nextDistance + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
