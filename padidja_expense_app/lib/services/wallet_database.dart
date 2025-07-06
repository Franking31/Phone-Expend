import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/wallet.dart';
import '../models/transaction.dart' as trans;

class WalletDatabase {
  static final WalletDatabase instance = WalletDatabase._init();
  static Database? _database;

  WalletDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path, 
      version: 6, // Incrémenté pour inclure le nouveau champ pieceJointe
      onCreate: _createDB, 
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future _onOpen(Database db) async {
    print("📂 Database opened, verifying tables...");
    await _verifyTables(db);
  }

  Future _verifyTables(Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('wallets', 'transactions', 'budgets')"
      );
      
      final existingTables = tables.map((t) => t['name'] as String).toSet();
      final requiredTables = {'wallets', 'transactions', 'budgets'};
      
      print("📋 Tables existantes: $existingTables");
      print("📋 Tables requises: $requiredTables");
      
      for (final table in requiredTables) {
        if (!existingTables.contains(table)) {
          print("⚠️ Table manquante: $table - Création...");
          await _createMissingTable(db, table);
        }
      }
    } catch (e) {
      print("❌ Erreur lors de la vérification des tables: $e");
    }
  }

  Future _createMissingTable(Database db, String tableName) async {
    final currentDateTime = DateTime.now().toIso8601String();
    
    switch (tableName) {
      case 'wallets':
        await db.execute('''
          CREATE TABLE IF NOT EXISTS wallets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            balance REAL NOT NULL,
            expenseLimit REAL DEFAULT 0.0,
            creationDate TEXT DEFAULT '$currentDateTime',
            lastUpdated TEXT DEFAULT '$currentDateTime',
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');
        break;
      case 'transactions':
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            source TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL
          )
        ''');
        break;
      case 'budgets':
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            nom TEXT,
            description TEXT,
            justificatif TEXT,
            pieceJointe TEXT, -- Nouveau champ pour les pièces jointes
            date TEXT NOT NULL
          )
        ''');
        break;
    }
    print("✅ Table $tableName créée avec succès");
  }

  Future _createDB(Database db, int version) async {
    print("🏗️ Création de la base de données version $version");
    
    final currentDateTime = DateTime.now().toIso8601String();
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        expenseLimit REAL DEFAULT 0.0,
        creationDate TEXT DEFAULT '$currentDateTime',
        lastUpdated TEXT DEFAULT '$currentDateTime',
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        nom TEXT,
        description TEXT,
        justificatif TEXT,
        pieceJointe TEXT, -- Nouveau champ pour les pièces jointes
        date TEXT NOT NULL
      )
    ''');
    
    print("✅ Toutes les tables créées avec succès");
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("🔄 Mise à jour de la base de données de v$oldVersion vers v$newVersion");
    
    try {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE wallets ADD COLUMN expenseLimit REAL DEFAULT 0.0');
        print("✅ Colonne expenseLimit ajoutée");
      }
      
      if (oldVersion < 3) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            date TEXT NOT NULL
          )
        ''');
        print("✅ Table budgets créée");
      }
      
      if (oldVersion < 4) {
        final tableInfo = await db.rawQuery("PRAGMA table_info(wallets)");
        final columnNames = tableInfo.map((row) => row['name'] as String).toSet();
        
        final currentDateTime = DateTime.now().toIso8601String();
        
        if (!columnNames.contains('creationDate')) {
          await db.execute('ALTER TABLE wallets ADD COLUMN creationDate TEXT');
          await db.execute('UPDATE wallets SET creationDate = ? WHERE creationDate IS NULL', [currentDateTime]);
          print("✅ Colonne creationDate ajoutée");
        }
        
        if (!columnNames.contains('lastUpdated')) {
          await db.execute('ALTER TABLE wallets ADD COLUMN lastUpdated TEXT');
          await db.execute('UPDATE wallets SET lastUpdated = ? WHERE lastUpdated IS NULL', [currentDateTime]);
          print("✅ Colonne lastUpdated ajoutée");
        }
        
        if (!columnNames.contains('isActive')) {
          await db.execute('ALTER TABLE wallets ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1');
          print("✅ Colonne isActive ajoutée");
        }
      }
      
      if (oldVersion < 5) {
        // Ajouter les nouveaux champs à la table budgets
        final budgetTableInfo = await db.rawQuery("PRAGMA table_info(budgets)");
        final budgetColumnNames = budgetTableInfo.map((row) => row['name'] as String).toSet();
        
        if (!budgetColumnNames.contains('nom')) {
          await db.execute('ALTER TABLE budgets ADD COLUMN nom TEXT');
          print("✅ Colonne nom ajoutée à la table budgets");
        }
        
        if (!budgetColumnNames.contains('description')) {
          await db.execute('ALTER TABLE budgets ADD COLUMN description TEXT');
          print("✅ Colonne description ajoutée à la table budgets");
        }
        
        if (!budgetColumnNames.contains('justificatif')) {
          await db.execute('ALTER TABLE budgets ADD COLUMN justificatif TEXT');
          print("✅ Colonne justificatif ajoutée à la table budgets");
        }
      }
      
      if (oldVersion < 6) {
        // Ajouter le nouveau champ pieceJointe
        final budgetTableInfo = await db.rawQuery("PRAGMA table_info(budgets)");
        final budgetColumnNames = budgetTableInfo.map((row) => row['name'] as String).toSet();
        
        if (!budgetColumnNames.contains('pieceJointe')) {
          await db.execute('ALTER TABLE budgets ADD COLUMN pieceJointe TEXT');
          print("✅ Colonne pieceJointe ajoutée à la table budgets");
        }
      }
      
      await _verifyTables(db);
      
    } catch (e) {
      print("❌ Erreur lors de la mise à jour: $e");
      rethrow;
    }
  }

  Future<void> ensureBudgetsTableExists() async {
    final db = await instance.database;
    try {
      await db.rawQuery("SELECT COUNT(*) FROM budgets LIMIT 1");
      print("✅ Table budgets existe déjà");
    } catch (e) {
      print("⚠️ Table budgets n'existe pas, création...");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT,
          nom TEXT,
          description TEXT,
          justificatif TEXT,
          pieceJointe TEXT, -- Nouveau champ pour les pièces jointes
          date TEXT NOT NULL
        )
      ''');
      print("✅ Table budgets créée avec succès");
    }
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await instance.database;
    try {
      await ensureBudgetsTableExists();
      return await db.query('budgets');
    } catch (e) {
      print("❌ Erreur lors de la récupération des budgets: $e");
      return [];
    }
  }

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await instance.database;
    try {
      await ensureBudgetsTableExists();
      return await db.insert('budgets', budget);
    } catch (e) {
      print("❌ Erreur lors de l'insertion du budget: $e");
      rethrow;
    }
  }

  // ▶️ Insert wallet
  Future<void> insertWallet(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      if (!wallet.validate()) throw Exception("Validation du portefeuille échouée");
      
      final existingWallets = await db.query(
        'wallets', 
        where: 'name = ?', 
        whereArgs: [wallet.name]
      );
      
      if (existingWallets.isNotEmpty) {
        print("⚠️ Un portefeuille '${wallet.name}' existe déjà");
        throw Exception("Un portefeuille avec le nom '${wallet.name}' existe déjà");
      }
      
      wallet.updateLastUpdated();
      final walletMap = wallet.toMap();
      final walletId = await db.insert('wallets', walletMap);
      print("💼 Portefeuille inséré avec ID: $walletId");
      
      final walletWithId = wallet.copyWith(id: walletId);
      await createWalletAdditionTransaction(walletWithId);
      
    } catch (e) {
      print("❌ Erreur lors de l'insertion du portefeuille: $e");
      rethrow;
    }
  }

  // ▶️ Get all wallets
  Future<List<Wallet>> getWallets() async {
    final db = await instance.database;
    final res = await db.query('wallets');
    return res.map((e) => Wallet.fromMap(e)).toList();
  }

  // ▶️ Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      if (!wallet.validate()) throw Exception("Validation du portefeuille échouée");
      if (wallet.id == null) {
        print("⚠️ L'ID du portefeuille est null, impossible de mettre à jour");
        throw Exception("L'ID du portefeuille est requis pour la mise à jour");
      }
      
      wallet.updateLastUpdated();
      final walletMap = wallet.toMap();
      print("🔄 Mise à jour du portefeuille avec ID: ${wallet.id}");
      final rowsAffected = await db.update(
        'wallets',
        walletMap,
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      
      if (rowsAffected == 0) {
        print("⚠️ Aucun portefeuille mis à jour avec ID: ${wallet.id}");
        throw Exception("Aucun portefeuille trouvé avec l'ID spécifié");
      }
      
      print("✅ Portefeuille mis à jour avec succès (ID: ${wallet.id}, Rows affectées: $rowsAffected)");
    } catch (e) {
      print("❌ Erreur lors de la mise à jour du portefeuille: $e");
      rethrow;
    }
  }

  // ▶️ Add expense limit
  Future<void> addExpenseLimit(int walletId, double amountToAdd) async {
    final db = await instance.database;
    
    try {
      final wallets = await db.query('wallets', where: 'id = ?', whereArgs: [walletId]);
      if (wallets.isEmpty) {
        print("⚠️ Aucun portefeuille trouvé avec ID: $walletId");
        throw Exception("Portefeuille non trouvé");
      }

      final wallet = Wallet.fromMap(wallets.first);
      final newExpenseLimit = wallet.expenseLimit + amountToAdd;

      print("🔧 Ajout de $amountToAdd FCFA à la limite de dépense de ${wallet.name} (ID: $walletId). Nouvelle limite: $newExpenseLimit");

      final updatedWallet = wallet.copyWith(expenseLimit: newExpenseLimit);
      updatedWallet.updateLastUpdated();
      final walletMap = updatedWallet.toMap();
      await db.update(
        'wallets',
        walletMap,
        where: 'id = ?',
        whereArgs: [walletId],
      );

      print("✅ Limite de dépense mise à jour pour le portefeuille ID: $walletId");
    } catch (e) {
      print("❌ Erreur lors de l'ajout de la limite de dépense: $e");
      rethrow;
    }
  }

  Future<void> insertTransactionWithoutBalanceUpdate(trans.Transaction tx) async {
    final db = await instance.database;
    print("Tentative d'insertion sans mise à jour du solde : ${tx.toMap()}");
    try {
      final txMap = tx.toMap();
      if (txMap['date'] is DateTime) {
        txMap['date'] = (txMap['date'] as DateTime).toIso8601String();
      }
      final id = await db.insert('transactions', txMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      print("Transaction insérée avec ID : $id (sans mise à jour du solde)");
    } catch (e) {
      print("Erreur lors de l'insertion : $e");
      rethrow;
    }
  }

  // ▶️ Insert transaction
  Future<void> insertTransaction(trans.Transaction tx) async {
    final db = await instance.database;
    print("Tentative d'insertion : ${tx.toMap()}");
    try {
      final txMap = tx.toMap();
      if (txMap['date'] is DateTime) {
        txMap['date'] = (txMap['date'] as DateTime).toIso8601String();
      }
      final id = await db.insert('transactions', txMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      print("Transaction insérée avec ID : $id");
      await _updateWalletBalance(tx);
    } catch (e) {
      print("Erreur lors de l'insertion : $e");
      rethrow;
    }
  }

  // 🔄 Update wallet balance after transaction
  Future<void> _updateWalletBalance(trans.Transaction tx) async {
    final db = await instance.database;
    print("Mise à jour du solde pour source : ${tx.source}");
    
    try {
      final wallets = await db.query('wallets', where: 'name = ?', whereArgs: [tx.source]);
      if (wallets.isEmpty) {
        print("Aucun portefeuille trouvé pour ${tx.source}");
        return;
      }
      
      final wallet = Wallet.fromMap(wallets.first);
      final newBalance = tx.type == 'income'
          ? wallet.balance + tx.amount
          : wallet.balance - tx.amount;
      
      print("Ancien solde: ${wallet.balance}, Nouveau solde calculé : $newBalance");
      
      final updatedWallet = wallet.copyWith(balance: newBalance);
      updatedWallet.updateLastUpdated();
      final walletMap = updatedWallet.toMap();
      await db.update(
        'wallets',
        walletMap,
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      
      print("Solde mis à jour pour ${wallet.name} à $newBalance");
    } catch (e) {
      print("Erreur lors de la mise à jour du solde : $e");
    }
  }

  // 📥 Get recent transactions
  Future<List<trans.Transaction>> getLatestTransactions(int limit) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'transactions', 
        orderBy: 'id DESC',
        limit: limit
      );
      print("Résultat brut de getLatestTransactions : $result");
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
        if (txMap['date'] is String) {
          txMap['date'] = DateTime.parse(txMap['date'] as String);
        }
        return trans.Transaction.fromMap(txMap);
      }).toList();
      
      print("Transactions converties : ${transactions.length} trouvées");
      return transactions;
    } catch (e) {
      print("Erreur lors de la récupération des transactions : $e");
      return [];
    }
  }

  // Méthode pour obtenir toutes les transactions
  Future<List<trans.Transaction>> getAllTransactions() async {
    final db = await instance.database;
    try {
      final result = await db.query('transactions', orderBy: 'id DESC');
      print("Toutes les transactions récupérées : ${result.length}");
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
        if (txMap['date'] is String) {
          txMap['date'] = DateTime.parse(txMap['date'] as String);
        }
        return trans.Transaction.fromMap(txMap);
      }).toList();
      
      print("Transactions converties avec succès : ${transactions.length}");
      return transactions;
    } catch (e) {
      print("Erreur lors de la récupération de toutes les transactions : $e");
      print("Stack trace: $e");
      return [];
    }
  }

  // 🗑️ Delete wallet
  Future<void> deleteWallet(int id) async {
    final db = await instance.database;
    try {
      final wallet = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
      if (wallet.isNotEmpty) {
        final walletData = Wallet.fromMap(wallet.first);
        print("Suppression du portefeuille : ${walletData.name} (ID: $id)");

       await insertTransactionWithoutBalanceUpdate(trans.Transaction(
          type: 'deletion',
          source: walletData.name,
          amount: 0.0,
          description: 'Suppression du portefeuille: ${walletData.name}',
          date: DateTime.now(),
        ));

        await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
        print("Portefeuille supprimé avec succès (ID: $id)");
      } else {
        print("Aucun portefeuille trouvé avec l'ID: $id");
      }
    } catch (e) {
      print("Erreur lors de la suppression du portefeuille : $e");
      rethrow;
    }
  }

  // Méthode de debug améliorée
  Future<void> debugDatabase() async {
    final db = await instance.database;
    try {
      await _verifyTables(db);
      
      final wallets = await db.query('wallets');
      final transactions = await db.query('transactions');
      final budgets = await getBudgets();
      
      print("=== DEBUG DATABASE DÉTAILLÉ ===");
      print("📊 Nombre de portefeuilles: ${wallets.length}");
      print("📊 Nombre de transactions: ${transactions.length}");
      print("📊 Nombre de budgets: ${budgets.length}");
      print("");
      
      print("💼 PORTEFEUILLES:");
      for (var wallet in wallets) {
        print("  - ID: ${wallet['id']}, Nom: ${wallet['name']}, Solde: ${wallet['balance']}, Limite: ${wallet['expenseLimit']}, Créé: ${wallet['creationDate']}, Mis à jour: ${wallet['lastUpdated']}, Actif: ${wallet['isActive']}");
      }
      print("");
      
      print("💰 TRANSACTIONS:");
      for (var transaction in transactions) {
        print("  - ID: ${transaction['id']}");
        print("    Type: ${transaction['type']}");
        print("    Source: ${transaction['source']}");
        print("    Montant: ${transaction['amount']}");
        print("    Description: ${transaction['description']}");
        print("    Date: ${transaction['date']}");
        print("    ---");
      }
      print("");
      
      print("💸 BUDGETS:");
      for (var budget in budgets) {
        print("  - ID: ${budget['id']}, Nom: ${budget['nom']}, Source: ${budget['source']}, Montant: ${budget['amount']}, Catégorie: ${budget['category']}, Description: ${budget['description']}, Justificatif: ${budget['justificatif']}, Pièce jointe: ${budget['pieceJointe']}, Date: ${budget['date']}");
      }
      print("===============================");
      
      final walletTableInfo = await db.rawQuery("PRAGMA table_info(wallets)");
      final transactionTableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
      final budgetTableInfo = await db.rawQuery("PRAGMA table_info(budgets)");
      
      print("🏗️ STRUCTURE TABLE WALLETS:");
      for (var col in walletTableInfo) {
        print("  - ${col['name']}: ${col['type']}");
      }
      
      print("🏗️ STRUCTURE TABLE TRANSACTIONS:");
      for (var col in transactionTableInfo) {
        print("  - ${col['name']}: ${col['type']}");
      }
      
      print("🏗️ STRUCTURE TABLE BUDGETS:");
      for (var col in budgetTableInfo) {
        print("  - ${col['name']}: ${col['type']}");
      }
      print("===============================");
      
    } catch (e) {
      print("❌ Erreur lors du debug de la base de données: $e");
    }
  }

  // 🧹 Clean
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
  
  Future<void> createWalletAdditionTransaction(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      final transactionSource = wallet.name;
      final transactionDescription = 'Ajout de portefeuille: ${wallet.name} (ID: ${wallet.id})';
      
      print("🚀 Création de transaction pour ${wallet.name} (ID: ${wallet.id})");
      
      final transaction = {
        'type': 'income',
        'source': transactionSource,
        'amount': wallet.balance,
        'description': transactionDescription,
        'date': DateTime.now().toIso8601String(),
      };
      
      final id = await db.insert('transactions', transaction);
      print("✅ Transaction créée avec ID: $id pour portefeuille ${wallet.name} (ID: ${wallet.id})");
      
      final check = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
      print("🔍 Vérification transaction: $check");
    } catch (e) {
      print("❌ Erreur lors de la création de transaction: $e");
      rethrow;
    }
  }

  Future<void> cleanDuplicateWallets() async {
    final db = await instance.database;
    try {
      final wallets = await db.query('wallets', orderBy: 'id ASC');
      final Map<String, List<Map<String, dynamic>>> walletsByName = {};
      
      for (var wallet in wallets) {
        final name = wallet['name'] as String;
        walletsByName[name] ??= [];
        walletsByName[name]!.add(wallet);
      }
      
      for (var entry in walletsByName.entries) {
        if (entry.value.length > 1) {
          print("🔧 Nettoyage des doublons pour '${entry.key}'");
          
          for (int i = 1; i < entry.value.length; i++) {
            final duplicateWallet = entry.value[i];
            await db.delete('wallets', where: 'id = ?', whereArgs: [duplicateWallet['id']]);
            await db.delete('transactions', where: 'description LIKE ?', whereArgs: ['%ID: ${duplicateWallet['id']}%']);
            print("🗑️ Supprimé le doublon ID: ${duplicateWallet['id']}");
          }
        }
      }
      
      print("✅ Nettoyage des doublons terminé");
    } catch (e) {
      print("❌ Erreur lors du nettoyage: $e");
    }
  }

  Future<void> recreateDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'wallet.db');
      
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      await deleteDatabase(path);
      print("🗑️ Ancienne base de données supprimée");
      
      _database = await _initDB('wallet.db');
      print("✅ Nouvelle base de données créée");
      
    } catch (e) {
      print("❌ Erreur lors de la recréation de la base de données: $e");
      rethrow;
    }
  }
}