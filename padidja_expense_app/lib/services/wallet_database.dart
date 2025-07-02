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

  // ▶️ Insert wallet - CORRIGÉ
  Future<void> insertWallet(Wallet wallet) async {
    final db = await instance.database;
    
    try {
      // Vérifier si un portefeuille avec ce nom existe déjà
      final existingWallets = await db.query(
        'wallets', 
        where: 'name = ?', 
        whereArgs: [wallet.name]
      );
      
      if (existingWallets.isNotEmpty) {
        print("⚠️ Un portefeuille '${wallet.name}' existe déjà");
        throw Exception("Un portefeuille avec le nom '${wallet.name}' existe déjà");
      }
      
      // Insérer le portefeuille
      final walletId = await db.insert('wallets', wallet.toMap());
      print("💼 Portefeuille inséré avec ID: $walletId");
      
      // Créer automatiquement la transaction d'ajout avec l'ID du portefeuille
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

  // 🔄 Update wallet balance after transaction - CORRIGÉ pour utiliser l'ID
  Future<void> _updateWalletBalance(trans.Transaction tx) async {
    final db = await instance.database;
    print("Mise à jour du solde pour source : ${tx.source}");
    
    try {
      // Utiliser l'ID du portefeuille si disponible, sinon chercher par nom
      List<Map<String, dynamic>> wallets;
      
      if (tx.source.contains('ID:')) {
        // Extraire l'ID de la source si présent
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

  // Méthode corrigée pour obtenir toutes les transactions
  Future<List<trans.Transaction>> getAllTransactions() async {
    final db = await instance.database;
    try {
      final result = await db.query('transactions', orderBy: 'id DESC');
      print("Toutes les transactions récupérées : ${result.length}");
      
      final transactions = result.map((map) {
        final txMap = Map<String, dynamic>.from(map);
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

  // 🗑️ Delete wallet - Ajout de la transaction de suppression sans ID
  Future<void> deleteWallet(int id) async {
    final db = await instance.database;
    try {
      // Récupérer les détails du portefeuille avant suppression
      final wallet = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
      if (wallet.isNotEmpty) {
        final walletData = Wallet.fromMap(wallet.first);
        print("Suppression du portefeuille : ${walletData.name} (ID: $id)");

        // Créer une transaction de suppression sans l'ID
        await insertTransactionWithoutBalanceUpdate(trans.Transaction(
          type: 'deletion',
          source: walletData.name,
          amount: 0.0, // Pas de montant pour une suppression
          description: 'Suppression du portefeuille: ${walletData.name}',
          date: DateTime.now(), // 10:53 AM WAT, 01 July 2025
        ));

        // Supprimer le portefeuille
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
  
  // CORRIGÉ - Création de transaction d'ajout de portefeuille sans ID
  Future<void> createWalletAdditionTransaction(Wallet wallet) async {
  final db = await instance.database;
  
  try {
    // Utiliser le nom du portefeuille et l'ID pour une description unique
    final transactionSource = wallet.name;
    final transactionDescription = 'Ajout de portefeuille: ${wallet.name} (ID: ${wallet.id})';
    
    print("🚀 Création de transaction pour ${wallet.name}");
    
    final transaction = {
      'type': 'income',
      'source': transactionSource,
      'amount': wallet.balance,
      'description': transactionDescription,
      'date': DateTime.now().toIso8601String(),
    };
    
    final id = await db.insert('transactions', transaction);
    print("✅ Transaction créée avec ID: $id pour portefeuille ${wallet.name} (ID: ${wallet.id})");
    
    // Vérifier l'insertion
    final check = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    print("🔍 Vérification transaction: $check");
  } catch (e) {
    print("❌ Erreur lors de la création de transaction: $e");
    rethrow; // Propager l'erreur à l'appelant
  }
}

  // Nouvelle méthode pour nettoyer les doublons
  Future<void> cleanDuplicateWallets() async {
    final db = await instance.database;
    try {
      final wallets = await db.query('wallets', orderBy: 'id ASC');
      final Map<String, List<Map<String, dynamic>>> walletsByName = {};
      
      // Grouper les portefeuilles par nom
      for (var wallet in wallets) {
        final name = wallet['name'] as String;
        walletsByName[name] ??= [];
        walletsByName[name]!.add(wallet);
      }
      
      // Supprimer les doublons (garder le premier de chaque nom)
      for (var entry in walletsByName.entries) {
        if (entry.value.length > 1) {
          print("🔧 Nettoyage des doublons pour '${entry.key}'");
          
          // Garder le premier, supprimer les autres
          for (int i = 1; i < entry.value.length; i++) {
            final duplicateWallet = entry.value[i];
            await db.delete('wallets', where: 'id = ?', whereArgs: [duplicateWallet['id']]);
            
            // Supprimer aussi les transactions associées
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
  
}