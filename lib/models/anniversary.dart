/// 纪念日模型
class Anniversary {
  final int? id;
  final String title;
  final String eventDate; // Format: "YYYY-MM-DD"
  final bool isRecurring; // 是否每年重复
  final String? type; // 纪念日类型
  final String? icon; // 图标 emoji
  final String? note; // 备注
  final int createdAt;

  Anniversary({
    this.id,
    required this.title,
    required this.eventDate,
    this.isRecurring = false,
    this.type,
    this.icon,
    this.note,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  DateTime get date => DateTime.parse(eventDate);
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// 计算距离纪念日的天数
  /// 正数表示未来，负数表示过去
  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (isRecurring) {
      // 每年重复的纪念日，计算今年或明年的日期
      var thisYearDate = DateTime(today.year, date.month, date.day);
      if (thisYearDate.isBefore(today)) {
        // 今年的已经过了，计算明年的
        thisYearDate = DateTime(today.year + 1, date.month, date.day);
      }
      return thisYearDate.difference(today).inDays;
    } else {
      // 一次性纪念日
      final targetDate = DateTime(date.year, date.month, date.day);
      return targetDate.difference(today).inDays;
    }
  }

  /// 是否是今天
  bool get isToday => daysUntil == 0;

  /// 是否已过去（仅对非重复纪念日有意义）
  bool get isPast => !isRecurring && daysUntil < 0;

  /// 是否即将到来（7天内）
  bool get isUpcoming => daysUntil > 0 && daysUntil <= 7;

  /// 获取显示文本
  String get displayText {
    final days = daysUntil;
    if (days == 0) {
      return '今天';
    } else if (days > 0) {
      return '还有 $days 天';
    } else {
      return '已过去 ${-days} 天';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'event_date': eventDate,
      'is_recurring': isRecurring ? 1 : 0,
      'type': type,
      'icon': icon,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory Anniversary.fromMap(Map<String, dynamic> map) {
    return Anniversary(
      id: map['id'] as int?,
      title: map['title'] as String,
      eventDate: map['event_date'] as String,
      isRecurring: (map['is_recurring'] as int?) == 1,
      type: map['type'] as String?,
      icon: map['icon'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as int?,
    );
  }

  Anniversary copyWith({
    int? id,
    String? title,
    String? eventDate,
    bool? isRecurring,
    String? type,
    String? icon,
    String? note,
    int? createdAt,
  }) {
    return Anniversary(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      isRecurring: isRecurring ?? this.isRecurring,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Anniversary(id: $id, title: $title, eventDate: $eventDate, isRecurring: $isRecurring)';
  }
}
