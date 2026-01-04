/// 待办事项模型
class TodoItem {
  final int? id;
  final String content;
  final String dateStr; // 格式: YYYY-MM-DD
  final bool isCompleted;
  final int createdAt;

  TodoItem({
    this.id,
    required this.content,
    required this.dateStr,
    this.isCompleted = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 从数据库 Map 创建实例
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as int?,
      content: map['content'] as String,
      dateStr: map['date_str'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'date_str': dateStr,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
    };
  }

  /// 复制并修改
  TodoItem copyWith({
    int? id,
    String? content,
    String? dateStr,
    bool? isCompleted,
    int? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      content: content ?? this.content,
      dateStr: dateStr ?? this.dateStr,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, content: $content, dateStr: $dateStr, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
