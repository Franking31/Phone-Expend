import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'padidja.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version to support migration
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE utilisateurs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT,
            email TEXT UNIQUE,
            mot_de_passe TEXT,
            role TEXT,
            image_path TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE lignes_budget (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            libelle TEXT,
            montant_alloue REAL,
            date_debut TEXT,
            date_fin TEXT,
            categorie_id INTEGER,
            numero_mission TEXT,
            numero_compte TEXT,
            description TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE depenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_budget INTEGER,
            montant REAL,
            description TEXT,
            justificatif TEXT,
            date TEXT,
            auteur_id INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE historique (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            utilisateur_id INTEGER,
            action TEXT,
            cible TEXT,
            date_action TEXT
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE utilisateurs ADD COLUMN image_path TEXT');
        }
      },
    );
  }
}