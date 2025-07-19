import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/spend_line.dart';
import '../services/supabase_service.dart';

class SpendLineDatabase {
  static final SpendLineDatabase instance = SpendLineDatabase._init();
  static Database? _database;

  SpendLineDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spend_lines.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
        date INTEGER,
        user_id TEXT,
        category TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE spend_lines ADD COLUMN user_id TEXT');
      print("✅ Colonne user_id ajoutée à la table spend_lines");
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE spend_lines ADD COLUMN category TEXT');
      print("✅ Colonne category ajoutée à la table spend_lines");
    }
  }

  Future<void> insert(SpendLine line) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId();
    final supabase = SupabaseService.client;
    
    if (userId == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    try {
      final lineMap = {
        'name': line.name,
        'description': line.description,
        'budget': line.budget,
        'proof': line.proof,
        'date': line.date.millisecondsSinceEpoch,
        'user_id': userId,
        'category': line.category,
      };
      
      // Insérer localement et récupérer l'ID généré
      final localId = await db.insert('spend_lines', lineMap);
      
      // Insérer dans Supabase avec l'ID local
      await supabase.from('spend_lines').insert({
        ...lineMap,
        'id': localId.toString(),
        'date': line.date.millisecondsSinceEpoch,
      });
      
      print('✅ SpendLine inséré localement (ID: $localId) et dans Supabase');
    } catch (e) {
      print('❌ Erreur lors de l\'insertion de SpendLine: $e');
      rethrow;
    }
  }

  Future<void> insertSpendTransaction(
    String name, 
    String description, 
    double amount, 
    String proof, 
    DateTime date, 
    {String? category}
  ) async {
    final db = await instance.database;
    final supabase = SupabaseService.client;
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    try {
      final lineMap = {
        'name': name,
        'description': description,
        'budget': amount,
        'proof': proof,
        'date': date.millisecondsSinceEpoch,
        'user_id': userId,
        'category': category,
      };
      
      // Insérer localement et récupérer l'ID généré
      final localId = await db.insert('spend_lines', lineMap);
      
      // Insérer dans Supabase avec l'ID local
      await supabase.from('spend_lines').insert({
        ...lineMap,
        'id': localId.toString(),
        'date': date.millisecondsSinceEpoch,
      });
      
      print("✅ Transaction de dépense ajoutée avec succès pour : $name, montant : $amount${category != null ? ', catégorie : $category' : ''} à ${date.toIso8601String()}");
    } catch (e) {
      print("❌ Erreur lors de l'ajout de la transaction de dépense : $e");
      rethrow;
    }
  }

  Future<List<SpendLine>> getAll() async {
    final db = await instance.database;
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      print('❌ Aucun utilisateur connecté');
      return [];
    }
    
    try {
      final result = await db.query(
        'spend_lines',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      
      return result.map((map) {
        // Don't modify the original map, just pass it directly to SpendLine.fromMap
        // The fromMap method will handle the date conversion
        return SpendLine.fromMap(map);
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des SpendLines: $e');
      return [];
    }
  }

  Future<List<SpendLine>> getByCategory(String category) async {
    final db = await instance.database;
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      print('❌ Aucun utilisateur connecté');
      return [];
    }
    
    try {
      final result = await db.query(
        'spend_lines',
        where: 'user_id = ? AND category = ?',
        whereArgs: [userId, category],
        orderBy: 'date DESC',
      );
      
      return result.map((map) {
        // Don't modify the original map, just pass it directly to SpendLine.fromMap
        // The fromMap method will handle the date conversion
        return SpendLine.fromMap(map);
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des SpendLines par catégorie: $e');
      return [];
    }
  }

  Future<List<String>> getAllCategories() async {
    final db = await instance.database;
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      print('❌ Aucun utilisateur connecté');
      return [];
    }
    
    try {
      final result = await db.query(
        'spend_lines',
        columns: ['category'],
        where: 'user_id = ? AND category IS NOT NULL AND category != ""',
        whereArgs: [userId],
        distinct: true,
      );
      return result
          .map((e) => e['category'] as String?)
          .where((cat) => cat != null && cat.isNotEmpty)
          .cast<String>()
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  Future<void> delete(int id) async {
    final db = await instance.database;
    final supabase = SupabaseService.client;
    final userId = await _getCurrentUserId();
    
    if (userId == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    
    try {
      // Supprimer localement
      await db.delete('spend_lines', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
      
      // Supprimer dans Supabase
      await supabase.from('spend_lines').delete().eq('id', id.toString()).eq('user_id', userId);
      
      print('✅ SpendLine supprimé localement et dans Supabase');
    } catch (e) {
      print('❌ Erreur lors de la suppression de SpendLine: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}