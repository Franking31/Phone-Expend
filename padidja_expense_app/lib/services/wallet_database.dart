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
  // Changez la version de 3 à 4
  return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _onUpgrade);
}

Future _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      balance REAL NOT NULL,
      expenseLimit REAL DEFAULT 0.0
    )
  ''');

  await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      source TEXT NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      date TEXT NOT NULL
    )
  ''');
  
  // Table budgets complète avec toutes les colonnes nécessaires
  await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      spent REAL DEFAULT 0.0,
      nom TEXT,
      description TEXT,
      justificatif TEXT,
      pieceJointe TEXT,
      date TEXT
    )
  ''');
}

Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    final tableInfo = await db.rawQuery("PRAGMA table_info(wallets)");
    final columnExists = tableInfo.any((column) => column['name'] == 'expenseLimit');
    if (!columnExists) {
      await db.execute('ALTER TABLE wallets ADD COLUMN expenseLimit REAL DEFAULT 0.0');
      print("✅ Column expenseLimit added successfully");
    } else {
      print("⚠️ Column expenseLimit already exists, skipping migration");
    }
  }
  
  if (oldVersion < 3) {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='budgets'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          spent REAL DEFAULT 0.0
        )
      ''');
      print("✅ Budgets table created successfully");
    } else {
      print("⚠️ Budgets table already exists, skipping creation");
    }
  }
  
  if (oldVersion < 4) {
    // Ajouter toutes les colonnes manquantes
    final tableInfo = await db.rawQuery("PRAGMA table_info(budgets)");
    final existingColumns = tableInfo.map((col) => col['name'] as String).toSet();
    
    final columnsToAdd = [
      'nom TEXT',
      'description TEXT', 
      'justificatif TEXT',
      'pieceJointe TEXT',
      'date TEXT'
    ];
    
    for (String columnDef in columnsToAdd) {
      final columnName = columnDef.split(' ')[0];
      if (!existingColumns.contains(columnName)) {
        await db.execute('ALTER TABLE budgets ADD COLUMN $columnDef');
        print("✅ Column $columnName added successfully to budgets table");
      } else {
        print("⚠️ Column $columnName already exists in budgets table, skipping migration");
      }
    }
  }
}

  // Ajoutez cette méthode dans wallet_database.dart dans la classe WalletDatabase

Future<List<Map<String, dynamic>>> getAllBudgets() async {
  final db = await instance.database;
  try {
    final budgets = await db.query('budgets', orderBy: 'id DESC');
    print("Tous les budgets récupérés : ${budgets.length}");
    return budgets;
  } catch (e) {
    print('Erreur lors de la récupération de tous les budgets: $e');
    return [];
  }
}

  Future<void> insertWallet(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      final existingWallets = await db.query(
        'wallets', 
        where: 'name = ?', 
        whereArgs: [wallet.name]
      );
      
      if (existingWallets.isNotEmpty) {
        print("⚠️ Un portefeuille '${wallet.name}' existe déjà");
        throw Exception("Un portefeuille avec le nom '${wallet.name}' existe déjà");
      }
      
      final walletId = await db.insert('wallets', wallet.toMap());
      print("💼 Portefeuille inséré avec ID: $walletId");
      
      final walletWithId = Wallet(
        id: walletId,
        name: wallet.name,
        balance: wallet.balance,
      );
      await createWalletAdditionTransaction(walletWithId);
      
    } catch (e) {
      print("❌ Erreur lors de l'insertion du portefeuille: $e");
      rethrow;
    }
  }

  Future<List<Wallet>> getWallets() async {
    final db = await instance.database;
    final res = await db.query('wallets');
    return res.map((e) => Wallet.fromMap(e)).toList();
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      if (wallet.id == null) {
        print("⚠️ L'ID du portefeuille est null, impossible de mettre à jour");
        throw Exception("L'ID du portefeuille est requis pour la mise à jour");
      }
      
      print("🔄 Mise à jour du portefeuille avec ID: ${wallet.id}");
      final rowsAffected = await db.update(
        'wallets',
        wallet.toMap(),
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

      await db.update(
        'wallets',
        {'expenseLimit': newExpenseLimit},
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

  Future<void> _updateWalletBalance(trans.Transaction tx) async {
    final db = await instance.database;
    print("Mise à jour du solde pour source : ${tx.source}");
    
    try {
      List<Map<String, dynamic>> wallets;
      
      if (tx.source.contains('ID:')) {
        final idMatch = RegExp(r'ID:(\d+)').firstMatch(tx.source);
        if (idMatch != null) {
          final walletId = int.parse(idMatch.group(1)!);
          wallets = await db.query('wallets', where: 'id = ?', whereArgs: [walletId]);
        } else {
          wallets = await db.query('wallets', where: 'name = ?', whereArgs: [tx.source]);
        }
      } else {
        wallets = await db.query('wallets', where: 'name = ?', whereArgs: [tx.source]);
      }
      
      if (wallets.isEmpty) {
        print("Aucun portefeuille trouvé pour ${tx.source}");
        return;
      }
      
      final wallet = Wallet.fromMap(wallets.first);
      final newBalance = tx.type == 'income'
          ? wallet.balance + tx.amount
          : wallet.balance - tx.amount;
      
      print("Ancien solde: ${wallet.balance}, Nouveau solde calculé : $newBalance");
      
      await db.update(
        'wallets',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      
      print("Solde mis à jour pour ${wallet.name} à $newBalance");
    } catch (e) {
      print("Erreur lors de la mise à jour du solde : $e");
    }
  }

  Future<List<trans.Transaction>> getLatestTransactions(int limit) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'transactions',
        orderBy: 'id DESC',
        limit: limit,
      );
      print("Résultat brut de getLatestTransactions : $result");
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
        print("Date brute de la DB: ${txMap['date']} (type: ${txMap['date'].runtimeType})");
        txMap['id'] = int.tryParse(txMap['id'].toString()) ?? 0;
        txMap['amount'] = (txMap['amount'] is num) ? (txMap['amount'] as num).toDouble() : 0.0;
        txMap['type'] = txMap['type'] as String? ?? 'unknown';
        txMap['source'] = txMap['source'] as String? ?? 'unknown';
        txMap['description'] = txMap['description'] as String? ?? '';
        txMap['date'] = txMap['date'] as String? ?? DateTime.now().toIso8601String();
        return trans.Transaction.fromMap(txMap);
      }).toList();
      
      print("Transactions converties : ${transactions.length} trouvées");
      return transactions;
    } catch (e) {
      print("Erreur lors de la récupération des transactions : $e");
      return [];
    }
  }

  Future<List<trans.Transaction>> getAllTransactions() async {
    final db = await instance.database;
    try {
      final result = await db.query('transactions', orderBy: 'id DESC');
      print("Toutes les transactions récupérées : ${result.length}");
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
        print("Date brute de la DB: ${txMap['date']} (type: ${txMap['date'].runtimeType})");
        txMap['id'] = int.tryParse(txMap['id'].toString()) ?? 0;
        txMap['amount'] = (txMap['amount'] is num) ? (txMap['amount'] as num).toDouble() : 0.0;
        txMap['type'] = txMap['type'] as String? ?? 'unknown';
        txMap['source'] = txMap['source'] as String? ?? 'unknown';
        txMap['description'] = txMap['description'] as String? ?? '';
        txMap['date'] = txMap['date'] as String? ?? DateTime.now().toIso8601String();
        return trans.Transaction.fromMap(txMap);
      }).toList();
      
      print("Transactions converties avec succès : ${transactions.length}");
      return transactions;
    } catch (e) {
      print("Erreur lors de la récupération de toutes les transactions : $e");
      return [];
    }
  }

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

  Future<void> debugDatabase() async {
    final db = await instance.database;
    try {
      final wallets = await db.query('wallets');
      final transactions = await db.query('transactions');
      
      print("=== DEBUG DATABASE DÉTAILLÉ ===");
      print("📊 Nombre de portefeuilles: ${wallets.length}");
      print("📊 Nombre de transactions: ${transactions.length}");
      print("");
      
      print("💼 PORTEFEUILLES:");
      for (var wallet in wallets) {
        print("  - ID: ${wallet['id']}, Nom: ${wallet['name']}, Solde: ${wallet['balance']}, Limite: ${wallet['expenseLimit']}");
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
      print("===============================");
      
      final walletTableInfo = await db.rawQuery("PRAGMA table_info(wallets)");
      final transactionTableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
      
      print("🏗️ STRUCTURE TABLE WALLETS:");
      for (var col in walletTableInfo) {
        print("  - ${col['name']}: ${col['type']}");
      }
      
      print("🏗️ STRUCTURE TABLE TRANSACTIONS:");
      for (var col in transactionTableInfo) {
        print("  - ${col['name']}: ${col['type']}");
      }
      print("===============================");
      
    } catch (e) {
      print("❌ Erreur lors du debug de la base de données: $e");
    }
  }

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

  Future<void> insertBudget(Map<String, dynamic> budget) async {
    final db = await instance.database;
    try {
      await db.insert('budgets', budget);
    } catch (e) {
      print('Erreur lors de l\'insertion du budget: $e');
      rethrow;
    }
  }

  Future<void> updateBudget(int id, Map<String, dynamic> budget) async {
    final db = await instance.database;
    try {
      await db.update('budgets', budget, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Erreur lors de la mise à jour du budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(int id) async {
    final db = await instance.database;
    try {
      await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Erreur lors de la suppression du budget: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBudgets(String source) async {
    final db = await instance.database;
    try {
      return await db.query('budgets', where: 'source = ?', whereArgs: [source]);
    } catch (e) {
      print('Erreur lors de la récupération des budgets: $e');
      return [];
    }
  }
}