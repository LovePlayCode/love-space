import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anniversary.dart';
import '../services/database_service.dart';

/// 纪念日状态
class AnniversaryNotifier extends StateNotifier<AsyncValue<List<Anniversary>>> {
  final DatabaseService _dbService = DatabaseService();

  AnniversaryNotifier() : super(const AsyncValue.loading()) {
    _loadAnniversaries();
  }

  Future<void> _loadAnniversaries() async {
    try {
      final anniversaries = await _dbService.getAllAnniversaries();
      // 按距离天数排序
      anniversaries.sort((a, b) {
        // 优先显示未来的，然后是今天的，最后是过去的
        if (a.daysUntil >= 0 && b.daysUntil < 0) return -1;
        if (a.daysUntil < 0 && b.daysUntil >= 0) return 1;
        return a.daysUntil.compareTo(b.daysUntil);
      });
      state = AsyncValue.data(anniversaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAnniversaries();
  }

  /// 添加纪念日
  Future<Anniversary?> addAnniversary(Anniversary anniversary) async {
    try {
      final id = await _dbService.insertAnniversary(anniversary);
      await refresh();
      return anniversary.copyWith(id: id);
    } catch (e) {
      return null;
    }
  }

  /// 更新纪念日
  Future<bool> updateAnniversary(Anniversary anniversary) async {
    try {
      await _dbService.updateAnniversary(anniversary);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 删除纪念日
  Future<bool> deleteAnniversary(int id) async {
    try {
      await _dbService.deleteAnniversary(id);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取指定 ID 的纪念日
  Anniversary? getById(int id) {
    return state.maybeWhen(
      data: (list) => list.where((a) => a.id == id).firstOrNull,
      orElse: () => null,
    );
  }
}

/// 纪念日 Provider
final anniversaryProvider = StateNotifierProvider<AnniversaryNotifier, AsyncValue<List<Anniversary>>>((ref) {
  return AnniversaryNotifier();
});

/// 即将到来的纪念日 Provider
final upcomingAnniversariesProvider = Provider<List<Anniversary>>((ref) {
  final anniversariesAsync = ref.watch(anniversaryProvider);
  return anniversariesAsync.maybeWhen(
    data: (list) => list.where((a) => a.daysUntil >= 0).take(5).toList(),
    orElse: () => [],
  );
});

/// 今日纪念日 Provider
final todayAnniversariesProvider = Provider<List<Anniversary>>((ref) {
  final anniversariesAsync = ref.watch(anniversaryProvider);
  return anniversariesAsync.maybeWhen(
    data: (list) => list.where((a) => a.isToday).toList(),
    orElse: () => [],
  );
});

/// 纪念日总数 Provider
final anniversaryCountProvider = Provider<int>((ref) {
  final anniversariesAsync = ref.watch(anniversaryProvider);
  return anniversariesAsync.maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});
