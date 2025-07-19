import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

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
      version: 6, // Incremented version for the fix
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE utilisateurs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT UNIQUE,
            nom TEXT,
            email TEXT UNIQUE,
            mot_de_passe TEXT,
            role TEXT,
            image_path TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source TEXT NOT NULL,
            category TEXT,
            amount REAL NOT NULL,
            spent REAL DEFAULT 0.0,
            nom TEXT,
            description TEXT,
            justificatif TEXT,
            date TEXT,
            user_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            source TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            justificatif TEXT,
            user_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE historique (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            utilisateur_id INTEGER,
            action TEXT,
            cible TEXT,
            date_action TEXT,
            user_id TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE utilisateurs ADD COLUMN image_path TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE utilisateurs ADD COLUMN user_id TEXT UNIQUE');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE budgets ADD COLUMN user_id TEXT');
          await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT');
          await db.execute('ALTER TABLE historique ADD COLUMN user_id TEXT');
          developer.log("✅ Colonnes user_id ajoutées aux tables locales", name: 'DatabaseService');
        }
        if (oldVersion < 5) {
          // Ajouter les colonnes manquantes pour alignement
          final tableInfoBudgets = await db.rawQuery("PRAGMA table_info(budgets)");
          final existingColumnsBudgets = tableInfoBudgets.map((col) => col['name'] as String).toSet();
          if (!existingColumnsBudgets.contains('category')) {
            await db.execute('ALTER TABLE budgets ADD COLUMN category TEXT');
          }
          if (!existingColumnsBudgets.contains('spent')) {
            await db.execute('ALTER TABLE budgets ADD COLUMN spent REAL DEFAULT 0.0');
          }
          if (!existingColumnsBudgets.contains('date')) {
            await db.execute('ALTER TABLE budgets ADD COLUMN date TEXT');
          }

          final tableInfoTransactions = await db.rawQuery("PRAGMA table_info(transactions)");
          final existingColumnsTransactions = tableInfoTransactions.map((col) => col['name'] as String).toSet();
          if (!existingColumnsTransactions.contains('justificatif')) {
            await db.execute('ALTER TABLE transactions ADD COLUMN justificatif TEXT');
          }
          developer.log("✅ Tables alignées avec les autres bases et Supabase", name: 'DatabaseService');
        }
        
        // NEW MIGRATION: Fix transactions table schema
        if (oldVersion < 6) {
          try {
            developer.log("🔄 Démarrage de la migration vers la version 6...", name: 'DatabaseService');
            
            // Create backup of existing transactions
            await db.execute('DROP TABLE IF EXISTS transactions_backup');
            await db.execute('''
              CREATE TABLE transactions_backup AS SELECT * FROM transactions
            ''');
            developer.log("✅ Sauvegarde des transactions existantes créée", name: 'DatabaseService');
            
            // Drop the problematic transactions table
            await db.execute('DROP TABLE IF EXISTS transactions');
            developer.log("✅ Ancienne table transactions supprimée", name: 'DatabaseService');
            
            // Recreate transactions table with proper schema
            await db.execute('''
              CREATE TABLE transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL,
                source TEXT NOT NULL,
                amount REAL NOT NULL,
                description TEXT,
                date TEXT NOT NULL,
                justificatif TEXT,
                user_id TEXT
              )
            ''');
            developer.log("✅ Nouvelle table transactions créée", name: 'DatabaseService');
            
            // Restore data from backup (excluding id to let AUTOINCREMENT work)
            await db.execute('''
              INSERT INTO transactions (type, source, amount, description, date, justificatif, user_id)
              SELECT type, source, amount, description, date, justificatif, user_id FROM transactions_backup
            ''');
            developer.log("✅ Données restaurées dans la nouvelle table", name: 'DatabaseService');
            
            // Clean up backup table
            await db.execute('DROP TABLE IF EXISTS transactions_backup');
            developer.log("✅ Table de sauvegarde supprimée", name: 'DatabaseService');
            
            developer.log("✅ Migration vers la version 6 terminée avec succès!", name: 'DatabaseService');
            
          } catch (e) {
            developer.log("❌ Erreur lors de la migration vers la version 6: $e", name: 'DatabaseService', error: e);
            
            // In case of error, try to restore from backup
            try {
              await db.execute('DROP TABLE IF EXISTS transactions');
              await db.execute('ALTER TABLE transactions_backup RENAME TO transactions');
              developer.log("✅ Table de sauvegarde restaurée après erreur", name: 'DatabaseService');
            } catch (restoreError) {
              developer.log("❌ Erreur lors de la restauration: $restoreError", name: 'DatabaseService', error: restoreError);
            }
          }
        }
      },
    );
  }

  // Méthode pour nettoyer les données d'un utilisateur spécifique
  static Future<void> clearUserData(String userId) async {
    final db = await database;
    await db.delete('utilisateurs', where: 'user_id != ?', whereArgs: [userId]);
    await db.delete('budgets', where: 'user_id != ?', whereArgs: [userId]);
    await db.delete('transactions', where: 'user_id != ?', whereArgs: [userId]);
    await db.delete('historique', where: 'user_id != ?', whereArgs: [userId]);
  }

  // Helper method for safe transaction insertion
  static Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    
    try {
      // Remove id if it exists to let AUTOINCREMENT work
      transaction.remove('id');
      
      developer.log('Inserting transaction: $transaction', name: 'DatabaseService');
      
      final result = await db.insert('transactions', transaction);
      developer.log('Transaction inserted with id: $result', name: 'DatabaseService');
      return result;
    } catch (e) {
      developer.log('Error inserting transaction: $e', name: 'DatabaseService', error: e);
      developer.log('Transaction data: $transaction', name: 'DatabaseService');
      rethrow;
    }
  }

  // Helper method to verify table schema
  static Future<void> verifyTableSchema() async {
    final db = await database;
    
    try {
      final tableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
      developer.log("📋 Schema de la table transactions:", name: 'DatabaseService');
      for (var column in tableInfo) {
        developer.log("  - ${column['name']}: ${column['type']} (PK: ${column['pk']})", name: 'DatabaseService');
      }
    } catch (e) {
      developer.log("❌ Erreur lors de la vérification du schéma: $e", name: 'DatabaseService', error: e);
    }
  }
}