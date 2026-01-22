import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../models/daily_log.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/todo_provider.dart';
import '../../models/todo_item.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  /// 根据心情 emoji 获取对应文案
  String _getMoodText(String? mood) {
    if (mood == null) return '写下心情';
    switch (mood) {
      case '🥰':
        return '今天很开心';
      case '😍':
        return '甜蜜恩爱';
      case '😐':
        return '平淡的一天';
      case '😢':
        return '有点难过';
      case '😡':
        return '心情不好';
      default:
        return '记录心情';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final markersAsync = ref.watch(calendarMarkersProvider);
    final dateLog = ref.watch(
      dateLogProvider(DailyLog.formatDateStr(selectedDate)),
    );
    final dateMediaAsync = ref.watch(dateMediaProvider(selectedDate));
    final todosAsync = ref.watch(
      todoListProvider(DailyLog.formatDateStr(selectedDate)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 背景点点图案
          const _DoodleBackground(),
          // 主内容
          Column(
            children: [
              // 固定的顶部标题栏
              _buildHeader(context),
              // 可滚动的内容
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // 日历卡片
                    SliverToBoxAdapter(
                      child: _buildCalendarCard(selectedDate, markersAsync),
                    ),
                    // 选中日期的回忆
                    SliverToBoxAdapter(
                      child: _buildDayMemories(
                        selectedDate,
                        dateLog,
                        dateMediaAsync,
                        todosAsync,
                      ),
                    ),
                    // 底部间距
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 12,
        24,
        16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '爱的日历',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).selectToday();
              setState(() => _focusedMonth = DateTime.now());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderCute),
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
                  Icons.today_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    DateTime selectedDate,
    AsyncValue<Set<String>> markersAsync,
  ) {
    final markers = markersAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <String>{},
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: AppColors.cuteShadow,
      ),
      child: Column(
        children: [
          // 月份切换
          _buildMonthHeader(),
          const SizedBox(height: 16),
          // 星期标题
          _buildWeekdayHeader(),
          const SizedBox(height: 8),
          // 日期网格
          _buildDaysGrid(selectedDate, markers),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final monthStr = DateFormat('yyyy年 M月', 'zh_CN').format(_focusedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _changeMonth(-1),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          monthStr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => _changeMonth(1),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
      );
    });
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid(DateTime selectedDate, Set<String> markers) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0=Sunday
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();

    final List<Widget> dayWidgets = [];

    // 空白占位
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // 日期
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateStr = DailyLog.formatDateStr(date);
      final isSelected = _isSameDay(date, selectedDate);
      final isToday = _isSameDay(date, today);
      final hasMarker = markers.contains(dateStr);

      dayWidgets.add(
        _buildDayCell(day, date, isSelected, isToday, hasMarker),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(
    int day,
    DateTime date,
    bool isSelected,
    bool isToday,
    bool hasMarker,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).selectDate(date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 16 : 12),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.accent, width: 2)
              : null,
          boxShadow: isSelected ? AppColors.cuteChunkyShadow : null,
        ),
        transform: isSelected ? Matrix4.identity().scaled(1.05) : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 日期数字
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.textWhite
                    : isToday
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
            // 有记录标记 - 爱心图标
            if (hasMarker)
              Positioned(
                bottom: 4,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 10,
                  color: isSelected ? AppColors.textWhite : AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDayMemories(
    DateTime selectedDate,
    DailyLog? log,
    AsyncValue<List> mediaAsync,
    AsyncValue<List<TodoItem>> todosAsync,
  ) {
    final dateStr = DateFormat('M月d日', 'zh_CN').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$dateStr 的回忆',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 时间线内容
          _buildTimeline(selectedDate, log, mediaAsync, todosAsync),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    DateTime selectedDate,
    DailyLog? log,
    AsyncValue<List> mediaAsync,
    AsyncValue<List<TodoItem>> todosAsync,
  ) {
    final hasLog = log != null && (log.hasMood || log.hasContent || log.hasTitle);
    final hasMedia = mediaAsync.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );
    final hasTodos = todosAsync.maybeWhen(
      data: (todos) => todos.isNotEmpty,
      orElse: () => false,
    );

    if (!hasLog && !hasMedia && !hasTodos) {
      return _buildEmptyState(selectedDate);
    }

    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
      ),
      child: Column(
        children: [
          // 日记卡片
          if (hasLog)
            _buildDiaryCard(log!, selectedDate),
          // 照片区域
          mediaAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (items) {
              if (items.isEmpty) return const SizedBox();
              return _buildPhotoSection(items.cast<AssetEntity>());
            },
          ),
          // 待办事项
          if (hasTodos)
            _buildTodoSection(todosAsync, DailyLog.formatDateStr(selectedDate)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DateTime selectedDate) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cuteShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.wb_sunny_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            '这一天还没有记录',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigateToDayDetail(selectedDate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '添加记录',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(DailyLog log, DateTime selectedDate) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 时间线节点
        Positioned(
          left: -23,
          top: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.wb_sunny_rounded, size: 8, color: Colors.white),
            ),
          ),
        ),
        // 日记卡片
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: Colors.white),
            boxShadow: AppColors.cuteShadow,
          ),
          child: Stack(
            children: [
              // 纸张纹理背景
              Positioned.fill(
                child: CustomPaint(
                  painter: _PaperTexturePainter(),
                ),
              ),
              // 内容
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 心情和时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (log.hasMood)
                            Text(log.mood!, style: const TextStyle(fontSize: 24)),
                          if (log.hasMood) const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getMoodText(log.mood),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(log.updatedAt),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  if (log.hasTitle || log.hasContent) ...[
                    const SizedBox(height: 12),
                    // 标题
                    if (log.hasTitle)
                      Text(
                        log.title!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (log.hasContent) ...[
                      if (log.hasTitle) const SizedBox(height: 8),
                      Text(
                        log.content!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
        // 编辑按钮
        Positioned(
          right: -8,
          bottom: 8,
          child: GestureDetector(
            onTap: () => _navigateToDayDetail(selectedDate),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(List<AssetEntity> mediaItems) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 时间线节点
        Positioned(
          left: -23,
          top: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.photo_camera_rounded, size: 8, color: Colors.white),
            ),
          ),
        ),
        // 照片列表
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediaItems.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == mediaItems.length) {
                  // 添加按钮
                  return Container(
                    width: 128,
                    height: 128,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPink,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.textHint.withValues(alpha: 0.5),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '添加',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final asset = mediaItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _AssetThumbnail(
                    asset: asset,
                    onTap: () => context.push('/album/photo/${asset.id}'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoSection(
    AsyncValue<List<TodoItem>> todosAsync,
    String dateStr,
  ) {
    return todosAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (todos) {
        if (todos.isEmpty) return const SizedBox();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 时间线节点
            Positioned(
              left: -23,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.checklist_rounded, size: 8, color: Colors.white),
                ),
              ),
            ),
            // 待办卡片
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
                boxShadow: AppColors.cuteShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '今日恋爱计划',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...todos.map((todo) => _buildTodoItem(todo, dateStr)),
                  _buildQuickAddInput(dateStr),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoItem(TodoItem todo, String dateStr) {
    return Dismissible(
      key: Key('todo_${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('删除待办'),
                content: const Text('确定要删除这条待办事项吗？'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('删除', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        ref.read(todoListProvider(dateStr).notifier).deleteTodo(todo.id!);
      },
      child: GestureDetector(
        onTap: () {
          ref.read(todoListProvider(dateStr).notifier).toggleComplete(todo.id!);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                todo.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 18,
                color: todo.isCompleted ? AppColors.success : AppColors.textHint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  todo.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: todo.isCompleted
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddInput(String dateStr) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 40,
      child: TextField(
        decoration: InputDecoration(
          hintText: '添加待办...',
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: const Icon(Icons.add_rounded, color: AppColors.textHint, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: AppColors.backgroundPink,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
        style: const TextStyle(fontSize: 13),
        cursorHeight: 16,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            ref.read(todoListProvider(dateStr).notifier).addTodo(value);
          }
        },
      ),
    );
  }

  void _navigateToDayDetail(DateTime date) {
    final dateStr = DailyLog.formatDateStr(date);
    // 检查当天是否有日记记录
    final log = ref.read(dateLogProvider(dateStr));
    final hasRecord = log != null && !log.isEmpty;
    
    if (hasRecord) {
      // 有记录，进入详情页
      context.push('/calendar/day/$dateStr');
    } else {
      // 没有记录，进入编辑页（创建）
      context.push('/calendar/day/$dateStr/edit');
    }
  }
}

/// 背景点点图案
class _DoodleBackground extends StatelessWidget {
  const _DoodleBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _DoodlePainter(),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 纸张纹理绘制器
class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;

    // 横线
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 竖线
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: AppColors.backgroundPink,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
