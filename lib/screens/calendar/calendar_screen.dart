import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final markersAsync = ref.watch(calendarMarkersProvider);
    final dateLog = ref.watch(
      dateLogProvider(DailyLog.formatDateStr(selectedDate)),
    );
    final dateMediaAsync = ref.watch(dateMediaProvider(selectedDate));
    final todosAsync = ref.watch(todoListProvider(DailyLog.formatDateStr(selectedDate)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('爱的日历'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(selectedDateProvider.notifier).selectToday();
              setState(() => _focusedDay = DateTime.now());
            },
            icon: const Icon(Icons.today_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // 日历
          _buildCalendar(selectedDate, markersAsync),
          // 分割线
          const Divider(height: 1),
          // 选中日期的内容
          Expanded(
            child: _buildDayContent(selectedDate, dateLog, dateMediaAsync, todosAsync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToDayDetail(selectedDate),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_rounded, color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildCalendar(
    DateTime selectedDate,
    AsyncValue<Set<String>> markersAsync,
  ) {
    final markers = markersAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <String>{},
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2000),
        lastDay: DateTime(2100),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'zh_CN',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTextStyles.subtitle1,
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.primary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.primaryLighter,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: const TextStyle(color: AppColors.primary),
          markerDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 6,
          markerMargin: const EdgeInsets.only(top: 6),
        ),
        eventLoader: (day) {
          final dateStr = DailyLog.formatDateStr(day);
          return markers.contains(dateStr) ? [true] : [];
        },
        onDaySelected: (selectedDay, focusedDay) {
          ref.read(selectedDateProvider.notifier).selectDate(selectedDay);
          setState(() => _focusedDay = focusedDay);
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
      ),
    );
  }

  Widget _buildDayContent(
    DateTime selectedDate,
    DailyLog? log,
    AsyncValue<List> mediaAsync,
    AsyncValue<List<TodoItem>> todosAsync,
  ) {
    final dateStr = DateFormat('M月d日 EEEE', 'zh_CN').format(selectedDate);
    final isToday = isSameDay(selectedDate, DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期标题
          Row(
            children: [
              Text(dateStr, style: AppTextStyles.subtitle1),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '今天',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // 心情
          if (log?.hasMood == true)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(log!.mood!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  const Text(
                    '今日心情',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // 日记内容
          if (log?.hasContent == true)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '日记',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(log!.content!, style: AppTextStyles.body2),
                ],
              ),
            ),
          // 待办事项预览
          _buildTodoPreview(todosAsync, DailyLog.formatDateStr(selectedDate)),
          // 照片
          mediaAsync.when(
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
            data: (mediaItems) {
              if (mediaItems.isEmpty) {
                if (log == null || log.isEmpty) {
                  return _buildEmptyDay(todosAsync);
                }
                return const SizedBox();
              }
              return _buildMediaGrid(mediaItems);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodoPreview(AsyncValue<List<TodoItem>> todosAsync, String dateStr) {
    return todosAsync.when(
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
      data: (todos) {
        if (todos.isEmpty) return const SizedBox();
        
        final completedCount = todos.where((t) => t.isCompleted).length;
        final totalCount = todos.length;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '待办事项',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: completedCount == totalCount 
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$completedCount/$totalCount',
                      style: TextStyle(
                        color: completedCount == totalCount 
                            ? AppColors.success 
                            : AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 显示最多 3 个待办
              ...todos.take(3).map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      todo.isCompleted 
                          ? Icons.check_circle_rounded 
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: todo.isCompleted 
                          ? AppColors.success 
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todo.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: todo.isCompleted 
                              ? AppColors.textHint 
                              : AppColors.textPrimary,
                          decoration: todo.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
              if (todos.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '还有 ${todos.length - 3} 项...',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyDay(AsyncValue<List<TodoItem>> todosAsync) {
    // 如果有待办事项，不显示空状态
    final hasTodos = todosAsync.maybeWhen(
      data: (todos) => todos.isNotEmpty,
      orElse: () => false,
    );
    if (hasTodos) return const SizedBox();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny_rounded,
            size: 48,
            color: AppColors.primaryLighter,
          ),
          const SizedBox(height: 12),
          const Text(
            '这一天还没有记录',
            style: TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                _navigateToDayDetail(ref.read(selectedDateProvider)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('添加记录'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List mediaItems) {
    return Column(
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
            Text(
              '照片',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
    );
  }

  void _navigateToDayDetail(DateTime date) {
    final dateStr = DailyLog.formatDateStr(date);
    context.push('/calendar/day/$dateStr');
  }
}
