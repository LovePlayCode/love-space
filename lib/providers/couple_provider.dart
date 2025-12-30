import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/couple_info.dart';
import '../services/storage_service.dart';

/// 情侣信息状态
class CoupleNotifier extends StateNotifier<AsyncValue<CoupleInfo>> {
  final StorageService _storageService = StorageService();

  CoupleNotifier() : super(const AsyncValue.loading()) {
    _loadCoupleInfo();
  }

  Future<void> _loadCoupleInfo() async {
    try {
      final info = await _storageService.getCoupleInfo();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadCoupleInfo();
  }

  Future<void> updateCoupleInfo(CoupleInfo info) async {
    try {
      await _storageService.saveCoupleInfo(info);
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setMyNickname(String nickname) async {
    final current = state.value;
    if (current != null) {
      await _storageService.setMyNickname(nickname);
      state = AsyncValue.data(current.copyWith(myNickname: nickname));
    }
  }

  Future<void> setPartnerNickname(String nickname) async {
    final current = state.value;
    if (current != null) {
      await _storageService.setPartnerNickname(nickname);
      state = AsyncValue.data(current.copyWith(partnerNickname: nickname));
    }
  }

  Future<void> setMyAvatar(String path) async {
    final current = state.value;
    if (current != null) {
      await _storageService.setMyAvatar(path);
      state = AsyncValue.data(current.copyWith(myAvatar: path));
    }
  }

  Future<void> setPartnerAvatar(String path) async {
    final current = state.value;
    if (current != null) {
      await _storageService.setPartnerAvatar(path);
      state = AsyncValue.data(current.copyWith(partnerAvatar: path));
    }
  }

  Future<void> setStartDate(DateTime date) async {
    final current = state.value;
    if (current != null) {
      await _storageService.setStartDate(date);
      state = AsyncValue.data(current.copyWith(startDate: date));
    }
  }
}

/// 情侣信息 Provider
final coupleProvider =
    StateNotifierProvider<CoupleNotifier, AsyncValue<CoupleInfo>>((ref) {
      return CoupleNotifier();
    });

/// 在一起天数 Provider
final daysTogetherProvider = Provider<int>((ref) {
  final coupleAsync = ref.watch(coupleProvider);
  return coupleAsync.maybeWhen(
    data: (info) => info.daysTogether,
    orElse: () => 0,
  );
});
