/// 情侣信息模型
class CoupleInfo {
  final String myNickname;
  final String partnerNickname;
  final String? myAvatar; // 本地路径
  final String? partnerAvatar; // 本地路径
  final DateTime? startDate; // 在一起的日期

  CoupleInfo({
    required this.myNickname,
    required this.partnerNickname,
    this.myAvatar,
    this.partnerAvatar,
    this.startDate,
  });

  /// 计算在一起的天数
  int get daysTogether {
    if (startDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    return today.difference(start).inDays + 1; // 包含当天
  }

  /// 是否已设置开始日期
  bool get hasStartDate => startDate != null;

  /// 是否已设置头像
  bool get hasMyAvatar => myAvatar != null && myAvatar!.isNotEmpty;
  bool get hasPartnerAvatar => partnerAvatar != null && partnerAvatar!.isNotEmpty;

  /// 获取显示的天数文本
  String get daysTogetherText {
    final days = daysTogether;
    if (days <= 0) return '0';
    return days.toString();
  }

  CoupleInfo copyWith({
    String? myNickname,
    String? partnerNickname,
    String? myAvatar,
    String? partnerAvatar,
    DateTime? startDate,
  }) {
    return CoupleInfo(
      myNickname: myNickname ?? this.myNickname,
      partnerNickname: partnerNickname ?? this.partnerNickname,
      myAvatar: myAvatar ?? this.myAvatar,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  String toString() {
    return 'CoupleInfo(myNickname: $myNickname, partnerNickname: $partnerNickname, daysTogether: $daysTogether)';
  }
}
