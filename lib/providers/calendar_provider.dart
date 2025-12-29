import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';
import '../models/media_item.dart';
import '../services/database_service.dart';
import '../services/media_service.dart';

/// 日历选中日期状态
class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier() : super(DateTime.now());

  void selectDate(DateTime date) {
    state = date;
  }

  void selectToday() {
    state = DateTime.now();
  }
}

/// 日记状态
class DailyLogNotifier extends StateNotifier<AsyncValue<Map<String, DailyLog>>> {
  final DatabaseService _dbService = DatabaseService();

  DailyLogNotifier() : super(const AsyncValue.loading()) {
    _loadAllLogs();
  }

  Future<void> _loadAllLogs() async {
    try {
      final logs = await _dbService.getAllDailyLogs();
      final logMap = <String, DailyLog>{};
      for (final log in logs) {
        logMap[log.dateStr] = log;
      }
      state = AsyncValue.data(logMap);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAllLogs();
  }

  /// 获取指定日期的日记
  DailyLog? getLogByDate(String dateStr) {
    return state.maybeWhen(
      data: (logs) => logs[dateStr],
      orElse: () => null,
    );
  }

  /// 保存日记
  Future<void> saveLog(DailyLog log) async {
    try {
      await _dbService.upsertDailyLog(log);
      await refresh();
    } catch (e) {
      // 处理错误
    }
  }

  /// 更新日记内容
  Future<void> updateContent(String dateStr, String content) async {
    final existing = getLogByDate(dateStr);
    final log = existing?.copyWith(content: content) ??
        DailyLog(dateStr: dateStr, content: content);
    await saveLog(log);
  }

  /// 更新心情
  Future<void> updateMood(String dateStr, String mood) async {
    final existing = getLogByDate(dateStr);
    final log = existing?.copyWith(mood: mood) ??
        DailyLog(dateStr: dateStr, mood: mood);
    await saveLog(log);
  }

  /// 删除日记
  Future<void> deleteLog(String dateStr) async {
    try {
      await _dbService.deleteDailyLog(dateStr);
      await refresh();
    } catch (e) {
      // 处理错误
    }
  }
}

/// 选中日期 Provider
final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  return SelectedDateNotifier();
});

/// 日记 Provider
final dailyLogProvider = StateNotifierProvider<DailyLogNotifier, AsyncValue<Map<String, DailyLog>>>((ref) {
  return DailyLogNotifier();
});

/// 有日记的日期集合 Provider
final logDatesProvider = FutureProvider<Set<String>>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getDailyLogDates();
});

/// 指定日期的日记 Provider
final dateLogProvider = Provider.family<DailyLog?, String>((ref, dateStr) {
  final logsAsync = ref.watch(dailyLogProvider);
  return logsAsync.maybeWhen(
    data: (logs) => logs[dateStr],
    orElse: () => null,
  );
});

/// 指定日期的媒体 Provider
final dateMediaProvider = FutureProvider.family<List<MediaItem>, DateTime>((ref, date) async {
  final mediaService = MediaService();
  return await mediaService.getMediaItemsByDate(date);
});

/// 日历标记数据 Provider（合并日记和媒体日期）
final calendarMarkersProvider = FutureProvider<Set<String>>((ref) async {
  final dbService = DatabaseService();
  
  // 获取有日记的日期
  final logDates = await dbService.getDailyLogDates();
  
  // 获取有媒体的日期
  final mediaDates = await dbService.getMediaDates();
  
  // 合并
  return {...logDates, ...mediaDates};
});
