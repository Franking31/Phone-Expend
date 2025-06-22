import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/spend_line.dart';

class SpendLineDatabase {
  static final SpendLineDatabase instance = SpendLineDatabase._init();
  static Database? _database;

  SpendLineDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spend_lines.db');
    _database = await openDatabase(path, version: 1, onCreate: _createDB);
    return _database!;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spend_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        budget REAL,
        proof TEXT,
        date TEXT
      )
    ''');
  }

  Future<void> insert(SpendLine line) async {
    final db = await instance.database;
    await db.insert('spend_lines', line.toMap());
  }

  Future<List<SpendLine>> getAll() async {
    final db = await instance.database;
    final result = await db.query('spend_lines', orderBy: 'date DESC');
    return result.map((e) => SpendLine.fromMap(e)).toList();
  }

  Future<void> delete(int id) async {
    final db = await instance.database;
    await db.delete('spend_lines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
