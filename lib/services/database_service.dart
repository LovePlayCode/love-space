import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';
import '../models/media_item.dart';
import '../models/daily_log.dart';
import '../models/anniversary.dart';
import '../models/tag.dart';
import '../models/todo_item.dart';

/// 数据库服务 - 管理 SQLite 数据库操作
class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建媒体表
    await db.execute('''
      CREATE TABLE media_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        local_path TEXT NOT NULL,
        thumbnail_path TEXT,
        live_video_path TEXT,
        taken_date INTEGER NOT NULL,
        caption TEXT,
        width INTEGER,
        height INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建日记表
    await db.execute('''
      CREATE TABLE daily_logs (
        date_str TEXT PRIMARY KEY,
        content TEXT,
        mood TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建纪念日表
    await db.execute('''
      CREATE TABLE anniversaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        event_date TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        type TEXT,
        icon TEXT,
        note TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_media_taken_date ON media_items(taken_date)');
    await db.execute('CREATE INDEX idx_anniversary_event_date ON anniversaries(event_date)');

    // 创建标签表
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        icon TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建媒体-标签关联表
    await db.execute('''
      CREATE TABLE media_tags (
        media_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (media_id, tag_id),
        FOREIGN KEY (media_id) REFERENCES media_items(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // 创建标签索引
    await db.execute('CREATE INDEX idx_media_tags_media_id ON media_tags(media_id)');
    await db.execute('CREATE INDEX idx_media_tags_tag_id ON media_tags(tag_id)');

    // 创建待办事项表
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        date_str TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_todos_date_str ON todos(date_str)');

    // 创建系统相册标签关联表（基于 asset_id）
    await db.execute('''
      CREATE TABLE system_asset_tags (
        asset_id TEXT NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (asset_id, tag_id),
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_system_asset_tags_asset_id ON system_asset_tags(asset_id)');
    await db.execute('CREATE INDEX idx_system_asset_tags_tag_id ON system_asset_tags(tag_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库版本升级逻辑
    if (oldVersion < 2) {
      // 添加 thumbnail_path 字段
      await db.execute('ALTER TABLE media_items ADD COLUMN thumbnail_path TEXT');
    }
    if (oldVersion < 3) {
      // 添加标签表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          color TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      // 添加媒体-标签关联表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS media_tags (
          media_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (media_id, tag_id),
          FOREIGN KEY (media_id) REFERENCES media_items(id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_tags_media_id ON media_tags(media_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_media_tags_tag_id ON media_tags(tag_id)');
    }
    if (oldVersion < 4) {
      // 添加标签 icon 字段
      await db.execute('ALTER TABLE tags ADD COLUMN icon TEXT');
    }
    if (oldVersion < 5) {
      // 添加 live_video_path 字段支持实况照片
      await db.execute('ALTER TABLE media_items ADD COLUMN live_video_path TEXT');
    }
    if (oldVersion < 6) {
      // 添加待办事项表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          date_str TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_date_str ON todos(date_str)');
    }
    if (oldVersion < 7) {
      // 添加系统相册标签关联表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS system_asset_tags (
          asset_id TEXT NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (asset_id, tag_id),
          FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_system_asset_tags_asset_id ON system_asset_tags(asset_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_system_asset_tags_tag_id ON system_asset_tags(tag_id)');
    }
  }

  // ==================== MediaItem 操作 ====================

  /// 插入媒体项（如果 localPath 已存在则跳过）
  Future<int> insertMediaItem(MediaItem item) async {
    final db = await database;
    // 检查是否已存在相同路径的媒体
    final existing = await db.query(
      'media_items',
      where: 'local_path = ?',
      whereArgs: [item.localPath],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      // 已存在，返回已有的 id
      return existing.first['id'] as int;
    }
    return await db.insert('media_items', item.toMap());
  }

  /// 获取所有媒体项（按时间倒序）
  Future<List<MediaItem>> getAllMediaItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      orderBy: 'taken_date DESC',
    );
    return maps.map((map) => MediaItem.fromMap(map)).toList();
  }

  /// 根据 ID 获取媒体项
  Future<MediaItem?> getMediaItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return MediaItem.fromMap(maps.first);
  }

  /// 获取指定日期范围的媒体项
  Future<List<MediaItem>> getMediaItemsByDateRange(int startTimestamp, int endTimestamp) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: 'taken_date >= ? AND taken_date < ?',
      whereArgs: [startTimestamp, endTimestamp],
      orderBy: 'taken_date DESC',
    );
    return maps.map((map) => MediaItem.fromMap(map)).toList();
  }

  /// 获取有媒体的日期列表
  Future<Set<String>> getMediaDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT date(taken_date / 1000, 'unixepoch', 'localtime') as date_str
      FROM media_items
    ''');
    return maps.map((map) => map['date_str'] as String).toSet();
  }

  /// 更新媒体项
  Future<int> updateMediaItem(MediaItem item) async {
    final db = await database;
    return await db.update(
      'media_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 删除媒体项
  Future<int> deleteMediaItem(int id) async {
    final db = await database;
    return await db.delete(
      'media_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取媒体总数
  Future<int> getMediaCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM media_items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== DailyLog 操作 ====================

  /// 插入或更新日记
  Future<void> upsertDailyLog(DailyLog log) async {
    final db = await database;
    await db.insert(
      'daily_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 根据日期获取日记
  Future<DailyLog?> getDailyLogByDate(String dateStr) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_logs',
      where: 'date_str = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return DailyLog.fromMap(maps.first);
  }

  /// 获取所有日记
  Future<List<DailyLog>> getAllDailyLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_logs',
      orderBy: 'date_str DESC',
    );
    return maps.map((map) => DailyLog.fromMap(map)).toList();
  }

  /// 获取有日记的日期列表
  Future<Set<String>> getDailyLogDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_logs',
      columns: ['date_str'],
    );
    return maps.map((map) => map['date_str'] as String).toSet();
  }

  /// 删除日记
  Future<int> deleteDailyLog(String dateStr) async {
    final db = await database;
    return await db.delete(
      'daily_logs',
      where: 'date_str = ?',
      whereArgs: [dateStr],
    );
  }

  // ==================== Anniversary 操作 ====================

  /// 插入纪念日
  Future<int> insertAnniversary(Anniversary anniversary) async {
    final db = await database;
    return await db.insert('anniversaries', anniversary.toMap());
  }

  /// 获取所有纪念日
  Future<List<Anniversary>> getAllAnniversaries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'anniversaries',
      orderBy: 'event_date ASC',
    );
    return maps.map((map) => Anniversary.fromMap(map)).toList();
  }

  /// 根据 ID 获取纪念日
  Future<Anniversary?> getAnniversaryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'anniversaries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Anniversary.fromMap(maps.first);
  }

  /// 获取即将到来的纪念日（按距离天数排序）
  Future<List<Anniversary>> getUpcomingAnniversaries({int limit = 5}) async {
    final anniversaries = await getAllAnniversaries();
    // 按距离天数排序
    anniversaries.sort((a, b) {
      final aDays = a.daysUntil.abs();
      final bDays = b.daysUntil.abs();
      // 优先显示未来的，然后是今天的，最后是过去的
      if (a.daysUntil >= 0 && b.daysUntil < 0) return -1;
      if (a.daysUntil < 0 && b.daysUntil >= 0) return 1;
      return aDays.compareTo(bDays);
    });
    return anniversaries.take(limit).toList();
  }

  /// 更新纪念日
  Future<int> updateAnniversary(Anniversary anniversary) async {
    final db = await database;
    return await db.update(
      'anniversaries',
      anniversary.toMap(),
      where: 'id = ?',
      whereArgs: [anniversary.id],
    );
  }

  /// 删除纪念日
  Future<int> deleteAnniversary(int id) async {
    final db = await database;
    return await db.delete(
      'anniversaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 通用操作 ====================

  // ==================== Tag 操作 ====================

  /// 插入标签
  Future<int> insertTag(Tag tag) async {
    final db = await database;
    return await db.insert('tags', tag.toMap());
  }

  /// 获取所有标签
  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// 根据 ID 获取标签
  Future<Tag?> getTagById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  /// 根据名称获取标签
  Future<Tag?> getTagByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  /// 更新标签
  Future<int> updateTag(Tag tag) async {
    final db = await database;
    return await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// 删除标签
  Future<int> deleteTag(int id) async {
    final db = await database;
    // 先删除关联
    await db.delete('media_tags', where: 'tag_id = ?', whereArgs: [id]);
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MediaTag 操作 ====================

  /// 为媒体添加标签
  Future<void> addTagToMedia(int mediaId, int tagId) async {
    final db = await database;
    await db.insert(
      'media_tags',
      {'media_id': mediaId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// 从媒体移除标签
  Future<void> removeTagFromMedia(int mediaId, int tagId) async {
    final db = await database;
    await db.delete(
      'media_tags',
      where: 'media_id = ? AND tag_id = ?',
      whereArgs: [mediaId, tagId],
    );
  }

  /// 获取媒体的所有标签
  Future<List<Tag>> getTagsForMedia(int mediaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN media_tags mt ON t.id = mt.tag_id
      WHERE mt.media_id = ?
      ORDER BY t.name ASC
    ''', [mediaId]);
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// 获取拥有指定标签的所有媒体 ID
  Future<List<int>> getMediaIdsForTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_tags',
      columns: ['media_id'],
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
    return maps.map((map) => map['media_id'] as int).toList();
  }

  /// 获取拥有指定标签的所有媒体
  Future<List<MediaItem>> getMediaItemsByTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.* FROM media_items m
      INNER JOIN media_tags mt ON m.id = mt.media_id
      WHERE mt.tag_id = ?
      ORDER BY m.taken_date DESC
    ''', [tagId]);
    return maps.map((map) => MediaItem.fromMap(map)).toList();
  }

  /// 获取拥有任意指定标签的所有媒体
  Future<List<MediaItem>> getMediaItemsByTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return getAllMediaItems();
    final db = await database;
    final placeholders = tagIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT m.* FROM media_items m
      INNER JOIN media_tags mt ON m.id = mt.media_id
      WHERE mt.tag_id IN ($placeholders)
      ORDER BY m.taken_date DESC
    ''', tagIds);
    return maps.map((map) => MediaItem.fromMap(map)).toList();
  }

  /// 设置媒体的标签（替换所有）
  Future<void> setTagsForMedia(int mediaId, List<int> tagIds) async {
    final db = await database;
    await db.transaction((txn) async {
      // 删除旧的关联
      await txn.delete('media_tags', where: 'media_id = ?', whereArgs: [mediaId]);
      // 添加新的关联
      for (final tagId in tagIds) {
        await txn.insert('media_tags', {'media_id': mediaId, 'tag_id': tagId});
      }
    });
  }

  /// 获取标签使用次数
  Future<int> getTagUsageCount(int tagId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM media_tags WHERE tag_id = ?',
      [tagId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== 系统相册标签操作 ====================

  /// 获取系统相册照片的标签
  Future<List<Tag>> getTagsForAsset(String assetId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN system_asset_tags sat ON t.id = sat.tag_id
      WHERE sat.asset_id = ?
    ''', [assetId]);
    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// 设置系统相册照片的标签（替换所有）
  Future<void> setTagsForAsset(String assetId, List<int> tagIds) async {
    final db = await database;
    await db.transaction((txn) async {
      // 删除旧的关联
      await txn.delete('system_asset_tags', where: 'asset_id = ?', whereArgs: [assetId]);
      // 添加新的关联
      for (final tagId in tagIds) {
        await txn.insert('system_asset_tags', {'asset_id': assetId, 'tag_id': tagId});
      }
    });
  }

  /// 获取拥有指定标签的所有系统相册照片 ID
  Future<List<String>> getAssetIdsByTag(int tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'system_asset_tags',
      columns: ['asset_id'],
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
    return maps.map((map) => map['asset_id'] as String).toList();
  }

  /// 获取拥有任意指定标签的所有系统相册照片 ID
  Future<List<String>> getAssetIdsByTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return [];
    final db = await database;
    final placeholders = tagIds.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT asset_id FROM system_asset_tags
      WHERE tag_id IN ($placeholders)
    ''', tagIds);
    return maps.map((map) => map['asset_id'] as String).toList();
  }

  /// 获取所有有标签的系统相册照片 ID
  Future<Set<String>> getAllTaggedAssetIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT asset_id FROM system_asset_tags'
    );
    return maps.map((map) => map['asset_id'] as String).toSet();
  }

  // ==================== TodoItem 操作 ====================

  /// 插入待办事项
  Future<int> insertTodo(TodoItem todo) async {
    final db = await database;
    return await db.insert('todos', todo.toMap());
  }

  /// 获取指定日期的待办事项
  Future<List<TodoItem>> getTodosByDate(String dateStr) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'date_str = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 更新待办事项
  Future<void> updateTodo(TodoItem todo) async {
    final db = await database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// 切换待办事项完成状态
  Future<void> toggleTodoComplete(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE todos SET is_completed = 1 - is_completed WHERE id = ?',
      [id],
    );
  }

  /// 删除待办事项
  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取有待办事项的日期集合
  Future<Set<String>> getTodoDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT date_str FROM todos',
    );
    return maps.map((map) => map['date_str'] as String).toSet();
  }

  /// 获取指定日期范围内有待办的日期及数量
  Future<Map<String, int>> getTodoCountsByDateRange(String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''SELECT date_str, COUNT(*) as count FROM todos 
         WHERE date_str >= ? AND date_str <= ? 
         GROUP BY date_str''',
      [startDate, endDate],
    );
    return {for (var map in maps) map['date_str'] as String: map['count'] as int};
  }

  // ==================== 通用操作（原有）====================

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空所有数据（用于测试或重置）
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('media_items');
    await db.delete('daily_logs');
    await db.delete('anniversaries');
  }
}
