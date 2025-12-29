/// 媒体项模型 - 照片/视频
class MediaItem {
  final int? id;
  final int type; // 0: Image, 1: Video
  final String localPath;
  final int takenDate; // 时间戳
  final String? caption;
  final int? width;
  final int? height;
  final int createdAt;

  MediaItem({
    this.id,
    required this.type,
    required this.localPath,
    required this.takenDate,
    this.caption,
    this.width,
    this.height,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  bool get isImage => type == 0;
  bool get isVideo => type == 1;

  DateTime get takenDateTime => DateTime.fromMillisecondsSinceEpoch(takenDate);
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  /// 计算瀑布流展示的宽高比
  double get aspectRatio {
    if (width != null && height != null && width! > 0 && height! > 0) {
      return width! / height!;
    }
    return 1.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'local_path': localPath,
      'taken_date': takenDate,
      'caption': caption,
      'width': width,
      'height': height,
      'created_at': createdAt,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int?,
      type: map['type'] as int,
      localPath: map['local_path'] as String,
      takenDate: map['taken_date'] as int,
      caption: map['caption'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      createdAt: map['created_at'] as int?,
    );
  }

  MediaItem copyWith({
    int? id,
    int? type,
    String? localPath,
    int? takenDate,
    String? caption,
    int? width,
    int? height,
    int? createdAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      takenDate: takenDate ?? this.takenDate,
      caption: caption ?? this.caption,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MediaItem(id: $id, type: $type, localPath: $localPath, takenDate: $takenDate)';
  }
}
