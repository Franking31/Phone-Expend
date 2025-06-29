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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL
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
  }
  

  // ▶️ Insert wallet
  Future<void> insertWallet(Wallet wallet) async {
  final db = await instance.database;
  
  try {
    // Insérer le portefeuille
    final walletId = await db.insert('wallets', wallet.toMap());
    print("💼 Portefeuille inséré avec ID: $walletId");
    
    // Créer automatiquement la transaction d'ajout
    await createWalletAdditionTransaction(wallet);
    
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

  Future<void> insertTransactionWithoutBalanceUpdate(trans.Transaction tx) async {
  final db = await instance.database;
  print("Tentative d'insertion sans mise à jour du solde : ${tx.toMap()}");
  try {
    // Convertir la date en string ISO avant insertion
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

  // ▶️ Insert transaction - CORRIGÉ
  Future<void> insertTransaction(trans.Transaction tx) async {
    final db = await instance.database;
    print("Tentative d'insertion : ${tx.toMap()}");
    try {
      // Convertir la date en string ISO avant insertion
      final txMap = tx.toMap();
      if (txMap['date'] is DateTime) {
        txMap['date'] = (txMap['date'] as DateTime).toIso8601String();
      }
      
      final id = await db.insert('transactions', txMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      print("Transaction insérée avec ID : $id");
      
      // Mettre à jour le solde du portefeuille
      await _updateWalletBalance(tx);
    } catch (e) {
      print("Erreur lors de l'insertion : $e");
      rethrow;
    }
  }

  // 🔄 Update wallet balance after transaction - CORRIGÉ
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

  // 📥 Get recent transactions - CORRIGÉ
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
      
      // LAISSER LA DATE COMME STRING - ne pas la convertir en DateTime
      // La classe Transaction.fromMap() se charge de la conversion
      print("Date brute de la DB: ${txMap['date']} (type: ${txMap['date'].runtimeType})");
      
      return trans.Transaction.fromMap(txMap);
    }).toList();
    
    print("Transactions converties : ${transactions.length} trouvées");
    return transactions;
  } catch (e) {
    print("Erreur lors de la récupération des transactions : $e");
    return [];
  }
}

  // Nouvelle méthode pour obtenir toutes les transactions
  // Méthode corrigée pour obtenir toutes les transactions
Future<List<trans.Transaction>> getAllTransactions() async {
  final db = await instance.database;
  try {
    final result = await db.query('transactions', orderBy: 'id DESC');
    print("Toutes les transactions récupérées : ${result.length}");
    
    final transactions = result.map((map) {
      final txMap = Map<String, dynamic>.from(map);
      
      // LAISSER LA DATE COMME STRING - ne pas la convertir en DateTime
      // La classe Transaction.fromMap() se charge de la conversion
      print("Date brute de la DB: ${txMap['date']} (type: ${txMap['date'].runtimeType})");
      
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
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  

  // Méthode pour vérifier le contenu de la base de données
 // Méthode de debug améliorée dans WalletDatabase

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
      print("  - ID: ${wallet['id']}, Nom: ${wallet['name']}, Solde: ${wallet['balance']}");
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
    
    // Vérifier la structure des tables
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
  // 🧹 Clean
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
  
  Future<void> createWalletAdditionTransaction(Wallet wallet) async {
  final db = await instance.database;
  
  try {
    // Vérifier si une transaction d'ajout existe déjà
    final existing = await db.query(
      'transactions',
      where: 'description LIKE ? AND source = ?',
      whereArgs: ['Ajout de portefeuille: ${wallet.name}', wallet.name],
    );
    
    if (existing.isEmpty) {
      print("🚀 Création forcée de transaction pour ${wallet.name}");
      
      final transaction = {
        'type': 'income',
        'source': wallet.name,
        'amount': wallet.balance,
        'description': 'Ajout de portefeuille: ${wallet.name}',
        'date': DateTime.now().toIso8601String(),
      };
      
      final id = await db.insert('transactions', transaction);
      print("✅ Transaction forcée créée avec ID: $id");
      
      // Vérifier l'insertion
      final check = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
      print("🔍 Vérification transaction: $check");
    } else {
      print("⚠️ Transaction d'ajout déjà existante pour ${wallet.name}");
    }
  } catch (e) {
    print("❌ Erreur lors de la création forcée de transaction: $e");
  }
}
}