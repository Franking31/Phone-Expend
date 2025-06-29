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
    await db.insert('wallets', wallet.toMap());
  }

  // ▶️ Get all wallets
  Future<List<Wallet>> getWallets() async {
    final db = await instance.database;
    final res = await db.query('wallets');
    return res.map((e) => Wallet.fromMap(e)).toList();
  }

  // ▶️ Insert transaction
  Future<void> insertTransaction(trans.Transaction tx) async {
    final db = await instance.database;
    await db.insert('transactions', tx.toMap());
    await _updateWalletBalance(tx);
  }

  // 🔄 Update wallet balance after transaction
  Future<void> _updateWalletBalance(trans.Transaction tx) async {
    final db = await instance.database;
    final wallets = await db.query('wallets', where: 'name = ?', whereArgs: [tx.source]);
    if (wallets.isEmpty) return;
    final wallet = Wallet.fromMap(wallets.first);

    final newBalance = tx.type == 'income'
        ? wallet.balance + tx.amount
        : wallet.balance - tx.amount;

    await db.update(
      'wallets',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  // 📥 Get recent transactions
  Future<List<trans.Transaction>> getLatestTransactions(int limit) async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC', limit: limit);
    return result.map((e) => trans.Transaction.fromMap(e)).toList();
  }

  // 🗑️ Delete wallet
  Future<void> deleteWallet(int id) async {
    final db = await instance.database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  // 🧹 Clean
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}