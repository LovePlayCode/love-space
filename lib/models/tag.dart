/// 标签模型
class Tag {
  final int? id;
  final String name;
  final String? color; // 十六进制颜色值，如 '#FF5722'
  final int createdAt;

  Tag({
    this.id,
    required this.name,
    this.color,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String?,
      createdAt: map['created_at'] as int?,
    );
  }

  Tag copyWith({
    int? id,
    String? name,
    String? color,
    int? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tag(id: $id, name: $name, color: $color)';
}

/// 媒体-标签关联
class MediaTag {
  final int mediaId;
  final int tagId;

  MediaTag({
    required this.mediaId,
    required this.tagId,
  });

  Map<String, dynamic> toMap() {
    return {
      'media_id': mediaId,
      'tag_id': tagId,
    };
  }

  factory MediaTag.fromMap(Map<String, dynamic> map) {
    return MediaTag(
      mediaId: map['media_id'] as int,
      tagId: map['tag_id'] as int,
    );
  }
}
