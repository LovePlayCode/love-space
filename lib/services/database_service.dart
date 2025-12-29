import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';
import '../models/media_item.dart';
import '../models/daily_log.dart';
import '../models/anniversary.dart';

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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库版本升级逻辑
  }

  // ==================== MediaItem 操作 ====================

  /// 插入媒体项
  Future<int> insertMediaItem(MediaItem item) async {
    final db = await database;
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
