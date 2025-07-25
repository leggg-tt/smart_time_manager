import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/user_time_block.dart';
import '../models/time_block_templates.dart';
import '../models/enums.dart';

class DatabaseService {
  // ?表示可空类型
  static Database? _database;
  // 数据库文件名
  static const String _dbName = 'smart_time_manager.db';
  // 版本号
  static const int _dbVersion = 1;

  // 单例模式(确保应用只有一个数据库连接)
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  // 只在第一次调用时创建数据库
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // 获取系统数据库目录路径
    final dbPath = await getDatabasesPath();
    // 拼接数据库路径
    final path = join(dbPath, _dbName);

    // 打开或创建数据库
    return await openDatabase(
      path,
      version: _dbVersion,
      // 首次创建时调用
      onCreate: _createDB,
      // 版本升级时调用
      onUpgrade: _upgradeDB,
    );
  }

  // 创建数据库表
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
    // 使用批量处理提高性能
    final batch = db.batch();
    // 获取预定义模板,转换为map以便存储
    for (final template in TimeBlockTemplates.defaultTemplates) {
      batch.insert('user_time_blocks', template.toMap());
    }
    await batch.commit();
  }

  // ========== 任务相关操作 ==========

  // 插入任务
  Future<String> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task.id;
  }

  // 获取所有任务
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      // 按时间降序排列
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // 按状态获取任务
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'status = ?',
      // status.index获取枚举的索引值
      whereArgs: [status.index],
      // 先按优先级,再按创建时间排序
      orderBy: 'priority DESC, createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // 按照日期获取任务
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await database;
    // 开始时间
    final startOfDay = DateTime(date.year, date.month, date.day);
    // 结束时间
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'tasks',
      where: 'scheduledStartTime >= ? AND scheduledStartTime < ?',
      // 使用时间戳进行范围查询
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      // 按计划开始时间升序排列
      orderBy: 'scheduledStartTime ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // 按id获取任务
  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',  // 查询的表名
      where: 'id = ?',
      whereArgs: [id],
      // 限制返回结果数量为1
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  // 更新任务
  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // 删除任务
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 时间块相关操作 ==========

  // 插入新时间块
  Future<String> insertTimeBlock(UserTimeBlock timeBlock) async {
    final db = await database;
    await db.insert('user_time_blocks', timeBlock.toMap());
    return timeBlock.id;
  }

  // 获取所有时间块
  Future<List<UserTimeBlock>> getAllTimeBlocks() async {
    final db = await database;
    final maps = await db.query(
      'user_time_blocks',
      where: 'isActive = ?',
      whereArgs: [1],  // 替换值
      orderBy: 'startTime ASC',
    );
    return maps.map((map) => UserTimeBlock.fromMap(map)).toList();
  }

  // 按星期获取时间块
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

  // 按时间块id获取时间块
  Future<UserTimeBlock?> getTimeBlockById(String id) async {
    final db = await database;
    final maps = await db.query(
      'user_time_blocks',
      where: 'id = ?',
      whereArgs: [id],
      // 限制结果数量为1
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserTimeBlock.fromMap(maps.first);
  }

  // 修改时间块
  Future<void> updateTimeBlock(UserTimeBlock timeBlock) async {
    final db = await database;
    await db.update(
      'user_time_blocks',
      timeBlock.toMap(),
      where: 'id = ?',
      whereArgs: [timeBlock.id],
    );
  }

  // 删除时间块
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

    // 将查询结果转换为统计数据Map
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