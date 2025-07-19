import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet.dart';
import '../models/transaction.dart' as trans;

class WalletDatabase {
  static final WalletDatabase instance = WalletDatabase._init();
  static Database? _database;
  static const String _logTag = 'WalletDatabase';

  WalletDatabase._init();

  // Logging helper methods
  void _logInfo(String message) {
    developer.log(message, name: _logTag, level: 800);
  }

  void _logWarning(String message) {
    developer.log(message, name: _logTag, level: 900);
  }

  void _logError(String message, [Object? error]) {
    developer.log(message, name: _logTag, level: 1000, error: error);
  }

  void _logDebug(String message) {
    developer.log(message, name: _logTag, level: 700);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 6, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        expense_limit REAL DEFAULT 0.0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        source TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        spent REAL DEFAULT 0.0,
        nom TEXT,
        description TEXT,
        justificatif TEXT,
        piece_jointe TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');
    _logInfo('Database tables created successfully');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logInfo('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(wallets)");
      final columnExists = tableInfo.any((column) => column['name'] == 'expense_limit');
      if (!columnExists) {
        await db.execute('ALTER TABLE wallets ADD COLUMN expense_limit REAL DEFAULT 0.0');
        _logInfo('Column expense_limit added successfully');
      } else {
        _logWarning('Column expense_limit already exists, skipping migration');
      }
    }
    
    if (oldVersion < 3) {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='budgets'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            source TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            spent REAL DEFAULT 0.0
          )
        ''');
        _logInfo('Budgets table created successfully');
      } else {
        _logWarning('Budgets table already exists, skipping creation');
      }
    }
    
    if (oldVersion < 4) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(budgets)");
      final existingColumns = tableInfo.map((col) => col['name'] as String).toSet();
      
      final columnsToAdd = [
        'nom TEXT',
        'description TEXT', 
        'justificatif TEXT',
        'piece_jointe TEXT',
        'date TEXT',
        'user_id TEXT'
      ];
      
      for (String columnDef in columnsToAdd) {
        final columnName = columnDef.split(' ')[0];
        if (!existingColumns.contains(columnName)) {
          await db.execute('ALTER TABLE budgets ADD COLUMN $columnDef');
          _logInfo('Column $columnName added successfully to budgets table');
        } else {
          _logWarning('Column $columnName already exists in budgets table, skipping migration');
        }
      }
    }

    if (oldVersion < 5) {
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='transactions'");
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            type TEXT NOT NULL,
            source TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            date TEXT NOT NULL
          )
        ''');
        _logInfo('Transactions table created successfully');
      } else {
        _logWarning('Transactions table already exists, skipping creation');
      }
    }

    if (oldVersion < 6) {
      final tableInfoWallets = await db.rawQuery("PRAGMA table_info(wallets)");
      final existingColumnsWallets = tableInfoWallets.map((col) => col['name'] as String).toSet();
      if (!existingColumnsWallets.contains('user_id')) {
        await db.execute('ALTER TABLE wallets ADD COLUMN user_id TEXT');
        _logInfo('Column user_id added successfully to wallets table');
      }

      final tableInfoBudgets = await db.rawQuery("PRAGMA table_info(budgets)");
      final existingColumnsBudgets = tableInfoBudgets.map((col) => col['name'] as String).toSet();
      if (!existingColumnsBudgets.contains('user_id')) {
        await db.execute('ALTER TABLE budgets ADD COLUMN user_id TEXT');
        _logInfo('Column user_id added successfully to budgets table');
      }

      final tableInfoTransactions = await db.rawQuery("PRAGMA table_info(transactions)");
      final existingColumnsTransactions = tableInfoTransactions.map((col) => col['name'] as String).toSet();
      if (!existingColumnsTransactions.contains('user_id')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN user_id TEXT');
        _logInfo('Column user_id added successfully to transactions table');
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> insertWallet(Wallet wallet) async {
    final db = await instance.database;
    final supabase = Supabase.instance.client;
    final userId = await _getCurrentUserId();

    if (userId == null) {
      _logError('No user logged in');
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      final existingWallets = await db.query(
        'wallets',
        where: 'name = ?',
        whereArgs: [wallet.name],
      );

      if (existingWallets.isNotEmpty) {
        _logWarning('Wallet with name "${wallet.name}" already exists');
        throw Exception("Un portefeuille avec le nom '${wallet.name}' existe déjà");
      }

      // Insert locally
      final walletId = await db.insert('wallets', {
        'user_id': userId,
        'name': wallet.name,
        'balance': wallet.balance,
        'expense_limit': wallet.expenseLimit,
      });
      _logInfo('Wallet inserted locally with ID: $walletId');

      // Insert in Supabase
      await supabase.from('wallets').insert({
        'id': walletId.toString(),
        'user_id': userId, // Utiliser legacy_user_id si nécessaire, sinon user_id temporaire
        'name': wallet.name,
        'balance': wallet.balance,
        'expense_limit': wallet.expenseLimit,
      });
      _logInfo('Wallet inserted in Supabase with ID: $walletId');

      final walletWithId = Wallet(
        id: walletId,
        name: wallet.name,
        balance: wallet.balance,
        expenseLimit: wallet.expenseLimit,
      );
      await createWalletAdditionTransaction(walletWithId);

      // Insert transaction in Supabase
      await supabase.from('transactions').insert({
        'type': 'income',
        'source': wallet.name,
        'amount': wallet.balance,
        'description': 'Ajout de portefeuille: ${wallet.name} (ID: $walletId)',
        'date': DateTime.now().toIso8601String(),
        'user_id': userId,
      });

      _logInfo('Wallet and transaction inserted successfully');
    } catch (e) {
      _logError('Error inserting wallet: $e');
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
        _logWarning('Wallet ID is null, cannot update');
        throw Exception("L'ID du portefeuille est requis pour la mise à jour");
      }
      
      _logDebug('Updating wallet with ID: ${wallet.id}');
      final rowsAffected = await db.update(
        'wallets',
        {
          'user_id': wallet.id.toString(), // À ajuster selon votre modèle Wallet
          'name': wallet.name,
          'balance': wallet.balance,
          'expense_limit': wallet.expenseLimit,
        },
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      
      if (rowsAffected == 0) {
        _logWarning('No wallet updated with ID: ${wallet.id}');
        throw Exception("Aucun portefeuille trouvé avec l'ID spécifié");
      }
      
      _logInfo('Wallet updated successfully (ID: ${wallet.id}, Rows affected: $rowsAffected)');
    } catch (e) {
      _logError('Error updating wallet', e);
      rethrow;
    }
  }

  Future<void> addExpenseLimit(int walletId, double amountToAdd) async {
    final db = await instance.database;
    
    try {
      final wallets = await db.query('wallets', where: 'id = ?', whereArgs: [walletId]);
      if (wallets.isEmpty) {
        _logWarning('No wallet found with ID: $walletId');
        throw Exception("Portefeuille non trouvé");
      }

      final wallet = Wallet.fromMap(wallets.first);
      final newExpenseLimit = wallet.expenseLimit + amountToAdd;

      _logDebug('Adding $amountToAdd FCFA to expense limit of ${wallet.name} (ID: $walletId). New limit: $newExpenseLimit');

      await db.update(
        'wallets',
        {'expense_limit': newExpenseLimit},
        where: 'id = ?',
        whereArgs: [walletId],
      );

      _logInfo('Expense limit updated for wallet ID: $walletId');
    } catch (e) {
      _logError('Error adding expense limit', e);
      rethrow;
    }
  }

  Future<void> insertTransactionWithoutBalanceUpdate(trans.Transaction tx) async {
    final db = await instance.database;
    _logDebug('Inserting transaction without balance update: ${tx.toMap()}');
    
    try {
      final txMap = tx.toMap();
      if (txMap['date'] is DateTime) {
        txMap['date'] = (txMap['date'] as DateTime).toIso8601String();
      }
      
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logError('No user logged in');
        throw Exception('Aucun utilisateur connecté');
      }

      txMap['user_id'] = userId;
      
      final id = await db.insert('transactions', txMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      _logInfo('Transaction inserted with ID: $id (without balance update)');
    } catch (e) {
      _logError('Error inserting transaction', e);
      rethrow;
    }
  }

  Future<void> insertTransaction(trans.Transaction tx) async {
    final db = await instance.database;
    final supabase = Supabase.instance.client;
    final userId = await _getCurrentUserId();

    if (userId == null) {
      _logError('No user logged in');
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      final txMap = tx.toMap();
      if (txMap['date'] is DateTime) {
        txMap['date'] = (txMap['date'] as DateTime).toIso8601String();
      }

      // Insert locally
      final id = await db.insert('transactions', {
        ...txMap,
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      _logInfo('Transaction inserted locally with ID: $id');

      // Insert in Supabase
      await supabase.from('transactions').insert({
        'id': id.toString(),
        'user_id': userId,
        'type': txMap['type'],
        'source': txMap['source'],
        'amount': txMap['amount'],
        'description': txMap['description'],
        'date': txMap['date'],
      });
      _logInfo('Transaction inserted in Supabase with ID: $id');

      await _updateWalletBalance(tx);
    } catch (e) {
      _logError('Error inserting transaction: $e');
      rethrow;
    }
  }

  Future<void> _updateWalletBalance(trans.Transaction tx) async {
    final db = await instance.database;
    _logDebug('Updating balance for source: ${tx.source}');
    
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
        _logWarning('No wallet found for ${tx.source}');
        return;
      }
      
      final wallet = Wallet.fromMap(wallets.first);
      final newBalance = tx.type == 'income'
          ? wallet.balance + tx.amount
          : wallet.balance - tx.amount;
      
      _logDebug('Old balance: ${wallet.balance}, New calculated balance: $newBalance');
      
      await db.update(
        'wallets',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      
      _logInfo('Balance updated for ${wallet.name} to $newBalance');
    } catch (e) {
      _logError('Error updating wallet balance', e);
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
      _logDebug('Raw result from getLatestTransactions: $result');
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
        _logDebug('Raw date from DB: ${txMap['date']} (type: ${txMap['date'].runtimeType})');
        txMap['id'] = int.tryParse(txMap['id'].toString()) ?? 0;
        txMap['amount'] = (txMap['amount'] is num) ? (txMap['amount'] as num).toDouble() : 0.0;
        txMap['type'] = txMap['type'] as String? ?? 'unknown';
        txMap['source'] = txMap['source'] as String? ?? 'unknown';
        txMap['description'] = txMap['description'] as String? ?? '';
        txMap['date'] = txMap['date'] as String? ?? DateTime.now().toIso8601String();
        return trans.Transaction.fromMap(txMap);
      }).toList();
      
      _logInfo('Converted transactions: ${transactions.length} found');
      return transactions;
    } catch (e) {
      _logError('Error retrieving transactions', e);
      return [];
    }
  }

  Future<List<trans.Transaction>> getAllTransactions() async {
    final db = await instance.database;
    try {
      final result = await db.query('transactions', orderBy: 'id DESC');
      _logInfo('All transactions retrieved: ${result.length}');
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
        _logDebug('Raw date from DB: ${txMap['date']} (type: ${txMap['date'].runtimeType})');
        txMap['id'] = int.tryParse(txMap['id'].toString()) ?? 0;
        txMap['amount'] = (txMap['amount'] is num) ? (txMap['amount'] as num).toDouble() : 0.0;
        txMap['type'] = txMap['type'] as String? ?? 'unknown';
        txMap['source'] = txMap['source'] as String? ?? 'unknown';
        txMap['description'] = txMap['description'] as String? ?? '';
        txMap['date'] = txMap['date'] as String? ?? DateTime.now().toIso8601String();
        return trans.Transaction.fromMap(txMap);
      }).toList();
      
      _logInfo('Transactions converted successfully: ${transactions.length}');
      return transactions;
    } catch (e) {
      _logError('Error retrieving all transactions', e);
      return [];
    }
  }

  Future<void> deleteWallet(int id) async {
    final db = await instance.database;
    final supabase = Supabase.instance.client;
    final userId = await _getCurrentUserId();

    try {
      final wallet = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
      if (wallet.isNotEmpty) {
        final walletData = Wallet.fromMap(wallet.first);
        _logInfo('Deleting wallet: ${walletData.name} (ID: $id)');

        // Insert deletion transaction
        await insertTransactionWithoutBalanceUpdate(trans.Transaction(
          type: 'deletion',
          source: walletData.name,
          amount: 0.0,
          description: 'Suppression du portefeuille: ${walletData.name}',
          date: DateTime.now(),
        ));

        // Delete locally
        await db.delete('wallets', where: 'id = ?', whereArgs: [id]);

        // Delete from Supabase only if userId is not null
        if (userId != null) {
          await supabase.from('wallets').delete().eq('id', id.toString()).eq('user_id', userId);
        }

        _logInfo('Wallet deleted successfully (ID: $id)');
      } else {
        _logWarning('No wallet found with ID: $id');
      }
    } catch (e) {
      _logError('Error deleting wallet', e);
      rethrow;
    }
  }

  Future<void> insertBudget(Map<String, dynamic> budget) async {
    final db = await instance.database;
    final supabase = Supabase.instance.client;
    final userId = await _getCurrentUserId();

    if (userId == null) {
      _logError('No user logged in');
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      // Insert locally
      final budgetId = await db.insert('budgets', {
        ...budget,
        'user_id': userId,
      });
      _logInfo('Budget inserted locally with ID: $budgetId');

      // Insert in Supabase
      await supabase.from('budgets').insert({
        'id': budgetId.toString(),
        'user_id': userId,
        'source': budget['source'],
        'category': budget['category'],
        'amount': budget['amount'],
        'spent': budget['spent'],
        'nom': budget['nom'],
        'description': budget['description'],
        'justificatif': budget['justificatif'],
        'piece_jointe': budget['piece_jointe'],
        'date': budget['date'],
      });
      _logInfo('Budget inserted in Supabase with ID: $budgetId');
    } catch (e) {
      _logError('Error inserting budget: $e');
      rethrow;
    }
  }

  Future<void> updateBudget(int id, Map<String, dynamic> budget) async {
    final db = await instance.database;
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logError('No user logged in');
        throw Exception('Aucun utilisateur connecté');
      }

      _logDebug('Updating budget with ID: $id');
      final rowsAffected = await db.update(
        'budgets',
        {
          'user_id': userId,
          'source': budget['source'],
          'category': budget['category'],
          'amount': budget['amount'],
          'spent': budget['spent'],
          'nom': budget['nom'],
          'description': budget['description'],
          'justificatif': budget['justificatif'],
          'piece_jointe': budget['piece_jointe'],
          'date': budget['date'],
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (rowsAffected == 0) {
        _logWarning('No budget updated with ID: $id');
        throw Exception("Aucun budget trouvé avec l'ID spécifié");
      }
      
      _logInfo('Budget updated successfully (ID: $id, Rows affected: $rowsAffected)');
    } catch (e) {
      _logError('Error updating budget', e);
      rethrow;
    }
  }

  Future<void> deleteBudget(int id) async {
    final db = await instance.database;
    try {
      await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
      _logInfo('Budget deleted successfully (ID: $id)');
    } catch (e) {
      _logError('Error deleting budget', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBudgets(String source) async {
    final db = await instance.database;
    try {
      final budgets = await db.query('budgets', where: 'source = ?', whereArgs: [source]);
      _logDebug('Retrieved ${budgets.length} budgets for source: $source');
      return budgets;
    } catch (e) {
      _logError('Error retrieving budgets', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    final db = await instance.database;
    try {
      final budgets = await db.query('budgets', orderBy: 'id DESC');
      _logInfo('All budgets retrieved: ${budgets.length}');
      return budgets;
    } catch (e) {
      _logError('Error retrieving all budgets', e);
      return [];
    }
  }

  Future<void> createWalletAdditionTransaction(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      final transactionSource = wallet.name;
      final transactionDescription = 'Ajout de portefeuille: ${wallet.name} (ID: ${wallet.id})';
      
      _logDebug('Creating transaction for ${wallet.name} (ID: ${wallet.id})');
      
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logError('No user logged in');
        throw Exception('Aucun utilisateur connecté');
      }

      final transaction = {
        'user_id': userId,
        'type': 'income',
        'source': transactionSource,
        'amount': wallet.balance,
        'description': transactionDescription,
        'date': DateTime.now().toIso8601String(),
      };
      
      final id = await db.insert('transactions', transaction);
      _logInfo('Transaction created with ID: $id for wallet ${wallet.name} (ID: ${wallet.id})');
      
      final check = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
      _logDebug('Transaction verification: $check');
    } catch (e) {
      _logError('Error creating transaction', e);
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
          _logInfo('Cleaning duplicates for "${entry.key}"');
          
          for (int i = 1; i < entry.value.length; i++) {
            final duplicateWallet = entry.value[i];
            await db.delete('wallets', where: 'id = ?', whereArgs: [duplicateWallet['id']]);
            
            await db.delete('transactions', where: 'description LIKE ?', whereArgs: ['%ID: ${duplicateWallet['id']}%']);
            
            _logInfo('Deleted duplicate ID: ${duplicateWallet['id']}');
          }
        }
      }
      
      _logInfo('Duplicate cleanup completed');
    } catch (e) {
      _logError('Error during cleanup', e);
    }
  }

  Future<void> debugDatabase() async {
    final db = await instance.database;
    try {
      final wallets = await db.query('wallets');
      final transactions = await db.query('transactions');
      
      _logInfo('=== DATABASE DEBUG DETAILED ===');
      _logInfo('Number of wallets: ${wallets.length}');
      _logInfo('Number of transactions: ${transactions.length}');
      
      _logInfo('WALLETS:');
      for (var wallet in wallets) {
        _logInfo('  - ID: ${wallet['id']}, Name: ${wallet['name']}, Balance: ${wallet['balance']}, Limit: ${wallet['expense_limit']}');
      }
      
      _logInfo('TRANSACTIONS:');
      for (var transaction in transactions) {
        _logInfo('  - ID: ${transaction['id']}');
        _logInfo('    Type: ${transaction['type']}');
        _logInfo('    Source: ${transaction['source']}');
        _logInfo('    Amount: ${transaction['amount']}');
        _logInfo('    Description: ${transaction['description']}');
        _logInfo('    Date: ${transaction['date']}');
        _logInfo('    ---');
      }
      
      final walletTableInfo = await db.rawQuery("PRAGMA table_info(wallets)");
      final transactionTableInfo = await db.rawQuery("PRAGMA table_info(transactions)");
      
      _logInfo('WALLETS TABLE STRUCTURE:');
      for (var col in walletTableInfo) {
        _logInfo('  - ${col['name']}: ${col['type']}');
      }
      
      _logInfo('TRANSACTIONS TABLE STRUCTURE:');
      for (var col in transactionTableInfo) {
        _logInfo('  - ${col['name']}: ${col['type']}');
      }
      
    } catch (e) {
      _logError('Error during database debug', e);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _logInfo('Database closed');
  }
}