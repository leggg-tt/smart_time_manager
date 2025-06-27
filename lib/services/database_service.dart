import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/user_time_block.dart';
import '../models/time_block_templates.dart';
import '../models/enums.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'smart_time_manager.db';
  static const int _dbVersion = 1;

  // 单例模式
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建任务表
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        durationMinutes INTEGER NOT NULL,
        deadline INTEGER,
        scheduledStartTime INTEGER,
        actualStartTime INTEGER,
        actualEndTime INTEGER,
        priority INTEGER NOT NULL,
        energyRequired INTEGER NOT NULL,
        focusRequired INTEGER NOT NULL,
        taskCategory INTEGER NOT NULL,
        status INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        completedAt INTEGER,
        preferredTimeBlockIds TEXT,
        avoidTimeBlockIds TEXT
      )
    ''');

    // 创建用户时间块表
    await db.execute('''
      CREATE TABLE user_time_blocks(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        daysOfWeek TEXT NOT NULL,
        energyLevel INTEGER NOT NULL,
        focusLevel INTEGER NOT NULL,
        suitableCategories TEXT NOT NULL,
        suitablePriorities TEXT NOT NULL,
        suitableEnergyLevels TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // 插入默认时间块模板
    await _insertDefaultTimeBlocks(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时使用
  }

  Future<void> _insertDefaultTimeBlocks(Database db) async {
    final batch = db.batch();
    for (final template in TimeBlockTemplates.defaultTemplates) {
      batch.insert('user_time_blocks', template.toMap());
    }
    await batch.commit();
  }

  // ========== 任务相关操作 ==========

  Future<String> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task.id;
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'priority DESC, createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'tasks',
      where: 'scheduledStartTime >= ? AND scheduledStartTime < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'scheduledStartTime ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 时间块相关操作 ==========

  Future<String> insertTimeBlock(UserTimeBlock timeBlock) async {
    final db = await database;
    await db.insert('user_time_blocks', timeBlock.toMap());
    return timeBlock.id;
  }

  Future<List<UserTimeBlock>> getAllTimeBlocks() async {
    final db = await database;
    final maps = await db.query(
      'user_time_blocks',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'startTime ASC',
    );
    return maps.map((map) => UserTimeBlock.fromMap(map)).toList();
  }

  Future<List<UserTimeBlock>> getTimeBlocksByDay(int dayOfWeek) async {
    final db = await database;
    final maps = await db.query(
      'user_time_blocks',
      where: 'isActive = ?',
      whereArgs: [1],
    );

    // 过滤包含指定星期的时间块
    return maps
        .map((map) => UserTimeBlock.fromMap(map))
        .where((block) => block.daysOfWeek.contains(dayOfWeek))
        .toList();
  }

  Future<UserTimeBlock?> getTimeBlockById(String id) async {
    final db = await database;
    final maps = await db.query(
      'user_time_blocks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserTimeBlock.fromMap(maps.first);
  }

  Future<void> updateTimeBlock(UserTimeBlock timeBlock) async {
    final db = await database;
    await db.update(
      'user_time_blocks',
      timeBlock.toMap(),
      where: 'id = ?',
      whereArgs: [timeBlock.id],
    );
  }

  Future<void> deleteTimeBlock(String id) async {
    final db = await database;
    await db.delete(
      'user_time_blocks',
      where: 'id = ? AND isDefault = ?',
      whereArgs: [id, 0], // 只能删除非默认时间块
    );
  }

  // ========== 统计相关操作 ==========

  Future<Map<String, int>> getTaskStatistics() async {
    final db = await database;

    // 获取各状态任务数量
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM tasks
      GROUP BY status
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      final status = TaskStatus.values[row['status'] as int];
      stats[status.toString()] = row['count'] as int;
    }

    return stats;
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}