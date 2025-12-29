import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/couple_info.dart';

/// 本地存储服务 - 管理 SharedPreferences 操作
class StorageService {
  static SharedPreferences? _prefs;
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== 首次启动 ====================

  Future<bool> isFirstLaunch() async {
    final p = await prefs;
    return p.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchDone() async {
    final p = await prefs;
    await p.setBool(AppConstants.keyIsFirstLaunch, false);
  }

  // ==================== 情侣信息 ====================

  Future<CoupleInfo> getCoupleInfo() async {
    final p = await prefs;
    final myNickname = p.getString(AppConstants.keyMyNickname) ?? AppConstants.defaultMyNickname;
    final partnerNickname = p.getString(AppConstants.keyPartnerNickname) ?? AppConstants.defaultPartnerNickname;
    final myAvatar = p.getString(AppConstants.keyMyAvatar);
    final partnerAvatar = p.getString(AppConstants.keyPartnerAvatar);
    final startDateStr = p.getString(AppConstants.keyStartDate);
    
    DateTime? startDate;
    if (startDateStr != null && startDateStr.isNotEmpty) {
      startDate = DateTime.tryParse(startDateStr);
    }

    return CoupleInfo(
      myNickname: myNickname,
      partnerNickname: partnerNickname,
      myAvatar: myAvatar,
      partnerAvatar: partnerAvatar,
      startDate: startDate,
    );
  }

  Future<void> saveCoupleInfo(CoupleInfo info) async {
    final p = await prefs;
    await p.setString(AppConstants.keyMyNickname, info.myNickname);
    await p.setString(AppConstants.keyPartnerNickname, info.partnerNickname);
    
    if (info.myAvatar != null) {
      await p.setString(AppConstants.keyMyAvatar, info.myAvatar!);
    }
    if (info.partnerAvatar != null) {
      await p.setString(AppConstants.keyPartnerAvatar, info.partnerAvatar!);
    }
    if (info.startDate != null) {
      await p.setString(AppConstants.keyStartDate, info.startDate!.toIso8601String());
    }
  }

  Future<void> setMyNickname(String nickname) async {
    final p = await prefs;
    await p.setString(AppConstants.keyMyNickname, nickname);
  }

  Future<void> setPartnerNickname(String nickname) async {
    final p = await prefs;
    await p.setString(AppConstants.keyPartnerNickname, nickname);
  }

  Future<void> setMyAvatar(String path) async {
    final p = await prefs;
    await p.setString(AppConstants.keyMyAvatar, path);
  }

  Future<void> setPartnerAvatar(String path) async {
    final p = await prefs;
    await p.setString(AppConstants.keyPartnerAvatar, path);
  }

  Future<void> setStartDate(DateTime date) async {
    final p = await prefs;
    await p.setString(AppConstants.keyStartDate, date.toIso8601String());
  }

  // ==================== 主题设置 ====================

  Future<int?> getThemeColor() async {
    final p = await prefs;
    return p.getInt(AppConstants.keyThemeColor);
  }

  Future<void> setThemeColor(int color) async {
    final p = await prefs;
    await p.setInt(AppConstants.keyThemeColor, color);
  }

  // ==================== 通用操作 ====================

  Future<void> clear() async {
    final p = await prefs;
    await p.clear();
  }
}
