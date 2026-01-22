import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/daily_log.dart';
import '../services/database_service.dart';
import '../services/system_album_service.dart';

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

/// 指定日期的媒体 Provider（合并系统相册当日照片和用户手动添加的照片）
final dateMediaProvider = FutureProvider.family<List<AssetEntity>, DateTime>((ref, date) async {
  final service = SystemAlbumService();
  final hasPermission = await service.requestPermission();
  if (!hasPermission) return [];

  final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final dbService = DatabaseService();

  try {
    // 1. 获取用户手动添加到该日期的照片 ID
    final manualAssetIds = await dbService.getAssetIdsByDate(dateStr);
    
    // 2. 获取系统相册中该日期拍摄的照片
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: startOfDay,
          max: endOfDay,
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    List<AssetEntity> systemAssets = [];
    if (albums.isNotEmpty) {
      final recentAlbum = albums.first;
      final count = await recentAlbum.assetCountAsync;
      if (count > 0) {
        systemAssets = await recentAlbum.getAssetListPaged(page: 0, size: count);
      }
    }

    // 3. 获取手动添加的照片（通过 assetId）
    List<AssetEntity> manualAssets = [];
    if (manualAssetIds.isNotEmpty) {
      for (final assetId in manualAssetIds) {
        final asset = await AssetEntity.fromId(assetId);
        if (asset != null) {
          manualAssets.add(asset);
        }
      }
    }

    // 4. 合并并去重（手动添加的优先显示在前面）
    final allAssetIds = <String>{};
    final result = <AssetEntity>[];
    
    // 先添加手动添加的
    for (final asset in manualAssets) {
      if (allAssetIds.add(asset.id)) {
        result.add(asset);
      }
    }
    
    // 再添加系统相册当日的（去重）
    for (final asset in systemAssets) {
      if (allAssetIds.add(asset.id)) {
        result.add(asset);
      }
    }

    return result;
  } catch (e) {
    return [];
  }
});

/// 日历标记数据 Provider（合并日记和待办日期）
final calendarMarkersProvider = FutureProvider<Set<String>>((ref) async {
  final dbService = DatabaseService();
  
  // 获取有日记的日期
  final logDates = await dbService.getDailyLogDates();
  
  // 获取有待办的日期
  final todoDates = await dbService.getTodoDates();
  
  // 合并（移除媒体日期，因为现在直接从系统相册读取）
  return {...logDates, ...todoDates};
});
