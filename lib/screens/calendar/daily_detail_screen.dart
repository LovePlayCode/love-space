import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/daily_log.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/common/toast_utils.dart';
import '../../widgets/todo_list_widget.dart';

class DailyDetailScreen extends ConsumerStatefulWidget {
  final String dateStr;

  const DailyDetailScreen({super.key, required this.dateStr});

  @override
  ConsumerState<DailyDetailScreen> createState() => _DailyDetailScreenState();
}

class _DailyDetailScreenState extends ConsumerState<DailyDetailScreen> {
  late TextEditingController _contentController;
  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _loadExistingLog();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _loadExistingLog() {
    final log = ref.read(dateLogProvider(widget.dateStr));
    if (log != null) {
      _contentController.text = log.content ?? '';
      _selectedMood = log.mood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.dateStr);
    final dateStr = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(date);
    final dateMediaAsync = ref.watch(dateMediaProvider(date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(dateStr),
        backgroundColor: AppColors.background,
        actions: [TextButton(onPressed: _saveLog, child: const Text('保存'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 心情选择
            _buildMoodSelector(),
            const SizedBox(height: 20),
            // 待办事项
            TodoListWidget(dateStr: widget.dateStr),
            const SizedBox(height: 20),
            // 日记输入
            _buildContentEditor(),
            const SizedBox(height: 20),
            // 当天照片
            _buildPhotosSection(dateMediaAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日心情', style: AppTextStyles.subtitle2),
          const SizedBox(height: 12),
          _buildEmojiRows(),
        ],
      ),
    );
  }

  Widget _buildEmojiRows() {
    final emojis = AppConstants.moodEmojis.entries.toList();
    final firstRow = emojis.sublist(0, 4);
    final secondRow = emojis.sublist(4, 8);

    Widget buildEmojiItem(MapEntry<String, String> entry) {
      final isSelected = _selectedMood == entry.value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedMood = isSelected ? null : entry.value;
            });
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLighter
                    : AppColors.backgroundPink,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(entry.value, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children:
              firstRow
                  .expand((e) => [buildEmojiItem(e), const SizedBox(width: 12)])
                  .toList()
                ..removeLast(),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              secondRow
                  .expand((e) => [buildEmojiItem(e), const SizedBox(width: 12)])
                  .toList()
                ..removeLast(),
        ),
      ],
    );
  }

  Widget _buildContentEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('写点什么...', style: AppTextStyles.subtitle2),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '记录今天发生了什么...',
              hintStyle: TextStyle(color: AppColors.textHint),
              border: InputBorder.none,
            ),
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(AsyncValue<List<AssetEntity>> mediaAsync) {
    return mediaAsync.when(
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
      data: (mediaItems) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text('今日照片', style: AppTextStyles.subtitle2),
                ],
              ),
              const SizedBox(height: 12),
              if (mediaItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.textHint,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '这一天还没有照片',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: mediaItems.length,
                  itemBuilder: (context, index) {
                    final asset = mediaItems[index];
                    return _AssetThumbnail(
                      asset: asset,
                      onTap: () => context.push('/album/photo/${asset.id}'),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveLog() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedMood == null) {
      // 如果内容和心情都为空，删除日记
      await ref.read(dailyLogProvider.notifier).deleteLog(widget.dateStr);
    } else {
      final log = DailyLog(
        dateStr: widget.dateStr,
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

/// 资源缩略图组件
class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _AssetThumbnail({
    required this.asset,
    required this.onTap,
  });

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _thumbnailData;

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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundPink,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: _thumbnailData != null
            ? Image.memory(
                _thumbnailData!,
                fit: BoxFit.cover,
              )
            : const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      ),
    );
  }
}
