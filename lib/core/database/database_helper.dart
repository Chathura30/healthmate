import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../../models/health_record.dart';
import '../../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('healthmate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        profile_image TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Health records table
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        water INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS health_records');
      await db.execute('DROP TABLE IF EXISTS users');
      await _createDB(db, newVersion);
    }
  }

  // USER OPERATIONS

  Future<User?> createUser(User user) async {
    final db = await instance.database;
    try {
      final id = await db.insert('users', user.toMap());
      return user.copyWith(id: id);
    } catch (e) {
      return null; // Email already exists
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> authenticateUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // HEALTH RECORD

  Future<HealthRecord> create(HealthRecord record, int userId) async {
    final db = await instance.database;
    final recordMap = record.toMap();
    recordMap['user_id'] = userId;
    final id = await db.insert('health_records', recordMap);
    return record.copyWith(id: id);
  }

  Future<List<HealthRecord>> readAllRecords(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'health_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => HealthRecord.fromMap(json)).toList();
  }

  Future<HealthRecord?> readRecord(int id, int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'health_records',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (maps.isNotEmpty) {
      return HealthRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<HealthRecord>> readRecordsByDate(String date, int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'health_records',
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );
    return result.map((json) => HealthRecord.fromMap(json)).toList();
  }

  Future<int> update(HealthRecord record) async {
    final db = await instance.database;
    return db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getTodaySummary(String todayDate, int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        SUM(steps) as totalSteps,
        SUM(calories) as totalCalories,
        SUM(water) as totalWater
      FROM health_records
      WHERE date = ? AND user_id = ?
    ''',
      [todayDate, userId],
    );

    if (result.isNotEmpty) {
      return {
        'steps': result.first['totalSteps'] as int? ?? 0,
        'calories': result.first['totalCalories'] as int? ?? 0,
        'water': result.first['totalWater'] as int? ?? 0,
      };
    }
    return {'steps': 0, 'calories': 0, 'water': 0};
  }

  //weekly summary
  Future<List<Map<String, dynamic>>> getWeeklySummary(int userId) async {
    final db = await instance.database;
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final result = await db.rawQuery(
      '''
      SELECT 
        date,
        SUM(steps) as steps,
        SUM(calories) as calories,
        SUM(water) as water
      FROM health_records
      WHERE user_id = ? 
        AND date >= ? 
        AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''',
      [
        userId,
        DateFormat('yyyy-MM-dd').format(sevenDaysAgo),
        DateFormat('yyyy-MM-dd').format(today),
      ],
    );

    return result;
  }

  // Get total statistics
  Future<Map<String, int>> getTotalStatistics(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT 
        SUM(steps) as totalSteps,
        SUM(calories) as totalCalories,
        SUM(water) as totalWater,
        COUNT(*) as totalRecords
      FROM health_records
      WHERE user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return {
        'steps': result.first['totalSteps'] as int? ?? 0,
        'calories': result.first['totalCalories'] as int? ?? 0,
        'water': result.first['totalWater'] as int? ?? 0,
        'records': result.first['totalRecords'] as int? ?? 0,
      };
    }
    return {'steps': 0, 'calories': 0, 'water': 0, 'records': 0};
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
