/// 日记模型
class DailyLog {
  final String dateStr; // Primary Key, Format: "YYYY-MM-DD"
  final String? title;
  final String? content;
  final String? mood; // emoji string
  final int updatedAt;

  DailyLog({
    required this.dateStr,
    this.title,
    this.content,
    this.mood,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  DateTime get date => DateTime.parse(dateStr);
  DateTime get updatedDateTime => DateTime.fromMillisecondsSinceEpoch(updatedAt);

  bool get hasTitle => title != null && title!.isNotEmpty;
  bool get hasContent => content != null && content!.isNotEmpty;
  bool get hasMood => mood != null && mood!.isNotEmpty;
  bool get isEmpty => !hasTitle && !hasContent && !hasMood;

  Map<String, dynamic> toMap() {
    return {
      'date_str': dateStr,
      'title': title,
      'content': content,
      'mood': mood,
      'updated_at': updatedAt,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      dateStr: map['date_str'] as String,
      title: map['title'] as String?,
      content: map['content'] as String?,
      mood: map['mood'] as String?,
      updatedAt: map['updated_at'] as int?,
    );
  }

  DailyLog copyWith({
    String? dateStr,
    String? title,
    String? content,
    String? mood,
    int? updatedAt,
  }) {
    return DailyLog(
      dateStr: dateStr ?? this.dateStr,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 从 DateTime 创建日期字符串
  static String formatDateStr(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'DailyLog(dateStr: $dateStr, title: $title, mood: $mood, hasContent: $hasContent)';
  }
}
