import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/daily_log.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/album_provider.dart';
import '../../widgets/common/toast_utils.dart';

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
        actions: [
          TextButton(
            onPressed: _saveLog,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 心情选择
            _buildMoodSelector(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日心情',
            style: AppTextStyles.subtitle2,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppConstants.moodEmojis.entries.map((entry) {
              final isSelected = _selectedMood == entry.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = isSelected ? null : entry.value;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLighter : AppColors.backgroundPink,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
              Text(
                '写点什么...',
                style: AppTextStyles.subtitle2,
              ),
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
              contentPadding: EdgeInsets.zero,
            ),
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(AsyncValue<List> mediaAsync) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '今日照片',
                        style: AppTextStyles.subtitle2,
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('添加'),
                  ),
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
                      Icon(Icons.add_photo_alternate_rounded, color: AppColors.textHint, size: 32),
                      SizedBox(height: 8),
                      Text(
                        '点击上方添加照片',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
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
                    final item = mediaItems[index];
                    return GestureDetector(
                      onTap: () => context.push('/album/photo/${item.id}'),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(item.localPath)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPhoto() async {
    await ref.read(albumProvider.notifier).pickAndImportImages();
    // 照片会自动刷新
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
