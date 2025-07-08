import 'package:flutter/material.dart';
import 'package:padidja_expense_app/screens/verify_wallet_screen.dart';
import 'package:padidja_expense_app/screens/notification_screen.dart';
import 'package:padidja_expense_app/screens/history_screen.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../services/wallet_database.dart';
import 'add_transaction_screen.dart';

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  List<Wallet> _wallets = [];
  List<Transaction> _transactions = [];
  List<Map<String, dynamic>> _budgets = [];
  final themeColor = const Color(0xFF6074F9);
  bool _isLoading = false;
  double _globalWalletLimit = 1000000.0;
  double _totalBudgetAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadGlobalWalletLimit();
    _loadBudgets();
  }

  Future<void> _loadGlobalWalletLimit() async {
    try {
      final db = await WalletDatabase.instance.database;
      final result = await db.query('settings', where: 'key = ?', whereArgs: ['global_wallet_limit']);
      if (result.isNotEmpty) {
        setState(() {
          _globalWalletLimit = double.parse(result.first['value'] as String);
        });
      } else {
        await db.insert('settings', {'key': 'global_wallet_limit', 'value': _globalWalletLimit.toString()});
      }
    } catch (e) {
      print('Erreur lors du chargement de la limite globale: $e');
    }
  }

  Future<void> _saveGlobalWalletLimit(double limit) async {
    try {
      final db = await WalletDatabase.instance.database;
      await db.update(
        'settings',
        {'value': limit.toString()},
        where: 'key = ?',
        whereArgs: ['global_wallet_limit'],
      );
      setState(() {
        _globalWalletLimit = limit;
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde de la limite globale: $e');
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final db = await WalletDatabase.instance.database;
      final result = await db.query('budgets'); // Charger tous les budgets sans filtre de source
      
      double totalBudget = 0.0;
      List<Map<String, dynamic>> budgets = [];
      
      for (var budget in result) {
        if (budget['source'] != null && budget['source'] is String && budget['amount'] is num) {
          budgets.add({
            'id': int.tryParse(budget['id'].toString()) ?? 0,
            'source': budget['source'] as String,
            'nom': budget['nom'] as String? ?? 'Sans nom',
            'amount': (budget['amount'] as num).toDouble(),
            'category': budget['category'] as String? ?? 'Unknown',
            'description': budget['description'] as String? ?? '',
            'justificatif': budget['justificatif'] as String? ?? '',
            'created_at': budget['created_at'] as String? ?? '',
          });
          totalBudget += (budget['amount'] as num).toDouble();
        } else {
          print('Budget invalide détecté: $budget');
        }
      }
      
      setState(() {
        _budgets = budgets;
        _totalBudgetAmount = totalBudget;
      });
    } catch (e) {
      print('Erreur lors du chargement des budgets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des budgets: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Map<String, double> _getBudgetsByName() {
    Map<String, double> budgetsBySource = {};
    
    for (var budget in _budgets) {
      if (budget['source'] != null && budget['source'] is String) {
        String source = budget['source'] as String;
        double amount = (budget['amount'] is num) ? (budget['amount'] as num).toDouble() : 0.0;
        
        if (budgetsBySource.containsKey(source)) {
          budgetsBySource[source] = budgetsBySource[source]! + amount;
        } else {
          budgetsBySource[source] = amount;
        }
      } else {
        print('Budget avec source null ou invalide détecté: $budget');
      }
    }
    
    return budgetsBySource;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final w = await WalletDatabase.instance.getWallets();
      final tx = await WalletDatabase.instance.getLatestTransactions(5);
      setState(() {
        _wallets = w;
        _transactions = tx;
      });
      await _loadBudgets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setGlobalWalletLimit() async {
    final controller = TextEditingController(text: _globalWalletLimit.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Définir la limite globale des portefeuilles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cette limite empêchera l\'ajout de nouveaux portefeuilles si la somme totale dépasse cette valeur'),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limite globale (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context, newLimit);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await _saveGlobalWalletLimit(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Limite globale mise à jour à ${result.toStringAsFixed(2)} FCFA'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

 // Dans WalletHomeScreen, modifiez la méthode _navigateToWalletVerification
Future<void> _navigateToWalletVerification() async {
  print("🚀 Navigation vers WalletVerificationScreen");
  
  final currentTotal = _wallets.fold<double>(0, (sum, w) => sum + w.balance) + _totalBudgetAmount;
  
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WalletVerificationScreen(
        currentTotalBalance: currentTotal,
        globalWalletLimit: _globalWalletLimit,
      ),
    ),
  );
  
  print("🔄 Retour de WalletVerificationScreen avec result: $result");
  
  // SOLUTION 1: Rechargement automatique après toute navigation
  print("🔄 Rechargement automatique des données");
  await _loadData();
  
  if (result == true && mounted) {
    print("✅ Result est true et widget est mounted");
    
    try {
      // Rechargement supplémentaire pour les nouveaux portefeuilles
      await _loadData();
      
      final wallets = await WalletDatabase.instance.getWallets();
      print("💼 Portefeuilles récupérés: ${wallets.length}");
      
      if (wallets.isNotEmpty) {
        final newWallet = wallets.last;
        print("🆕 Nouveau portefeuille: ${newWallet.name} avec balance ${newWallet.balance}");
        
        final existingTransactions = await WalletDatabase.instance.getAllTransactions();
        final walletCreationTx = existingTransactions.where(
          (tx) => tx.description.contains('Ajout de portefeuille: ${newWallet.name}')
        ).toList();
        
        print("🔍 Transactions existantes pour ce portefeuille: ${walletCreationTx.length}");
        
        if (walletCreationTx.isEmpty) {
          final transaction = Transaction(
            type: 'income',
            amount: newWallet.balance,
            description: 'Ajout de portefeuille: ${newWallet.name}',
            date: DateTime.now(),
            source: newWallet.name,
          );
          
          print("💰 Création de la transaction: ${transaction.toMap()}");
          
          final db = await WalletDatabase.instance.database;
          final txMap = transaction.toMap();
          txMap['date'] = DateTime.now().toIso8601String();
          
          print("📝 Insertion directe dans la DB: $txMap");
          
          final id = await db.insert('transactions', txMap);
          print("✅ Transaction insérée avec ID: $id");
          
          // Rechargement final après insertion
          await _loadData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Portefeuille "${newWallet.name}" ajouté avec succès !'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print("⚠️ Transaction déjà existante pour ce portefeuille");
        }
      } else {
        print("❌ Aucun portefeuille trouvé après ajout");
      }
    } catch (e) {
      print("❌ Erreur dans _navigateToWalletVerification: $e");
      print("📊 Stack trace: ${StackTrace.current}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  } else {
    print("⚠️ Result n'est pas true ou widget n'est pas mounted - result: $result, mounted: $mounted");
  }
}

  Future<void> _deleteWallet(Wallet wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le portefeuille'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${wallet.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await WalletDatabase.instance.deleteWallet(wallet.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Portefeuille "${wallet.name}" supprimé'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression : $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _setOrUpdateExpenseLimit(Wallet wallet) async {
    final controller = TextEditingController(text: wallet.expenseLimit.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Définir/Modifier la limite de dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Portefeuille : ${wallet.name}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limite de dépense (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context, newLimit);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result >= 0) {
      try {
        wallet.expenseLimit = result;
        await WalletDatabase.instance.updateWallet(wallet);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Limite de dépense mise à jour pour "${wallet.name}" à ${result.toStringAsFixed(2)} FCFA'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour : $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _addExpenseLimit(Wallet wallet) async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un montant à la limite de dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Portefeuille : ${wallet.name}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant à ajouter (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context, amount);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      try {
        await WalletDatabase.instance.addExpenseLimit(wallet.id!, result);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ajouté ${result.toStringAsFixed(2)} FCFA à la limite de dépense de "${wallet.name}"'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'ajout : $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _setGlobalExpenseLimit() async {
    final controller = TextEditingController(text: _wallets.isNotEmpty ? (_wallets.map((w) => w.expenseLimit).reduce((a, b) => a + b)).toStringAsFixed(2) : '0.0');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Définir la limite globale de dépense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cette limite s\'appliquera uniformément à tous les portefeuilles'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limite globale (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context, newLimit);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result >= 0 && _wallets.isNotEmpty) {
      try {
        for (var wallet in _wallets) {
          wallet.expenseLimit = result;
          await WalletDatabase.instance.updateWallet(wallet);
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Limite globale mise à jour à ${result.toStringAsFixed(2)} FCFA pour tous les portefeuilles'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour : $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _addToGlobalExpenseLimit() async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter un montant à la limite globale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ce montant sera ajouté uniformément à tous les portefeuilles'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant à ajouter (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              Navigator.pop(context, amount);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && result > 0 && _wallets.isNotEmpty) {
      try {
        for (var wallet in _wallets) {
          await WalletDatabase.instance.addExpenseLimit(wallet.id!, result);
        }
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ajouté ${result.toStringAsFixed(2)} FCFA à la limite globale de tous les portefeuilles'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'ajout : $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final prefix = isIncome ? '+' : '-';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      transaction.source,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FCFA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(String budgetSource, double totalAmount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budgetSource,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BUDGET',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FCFA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _wallets.fold<double>(0, (sum, w) => sum + w.balance);
    final totalExpenseLimit = _wallets.isNotEmpty ? _wallets.map((w) => w.expenseLimit).reduce((a, b) => a + b) : 0.0;
    final totalWithBudgets = totalBalance + _totalBudgetAmount;
    final percentageUsed = _globalWalletLimit > 0 ? (totalWithBudgets / _globalWalletLimit * 100) : 0.0;
    final budgetsByName = _getBudgetsByName();

    return MainDrawerWrapper(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40),
                            const Text(
                              'Tableau de bord',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6074F9),
                              ),
                            ),
                            buildNotificationAction(context),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Limite globale des portefeuilles',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6074F9),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings, color: Color(0xFF6074F9), size: 20),
                                    onPressed: _setGlobalWalletLimit,
                                    tooltip: 'Modifier la limite globale',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${totalWithBudgets.toStringAsFixed(2)} FCFA',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6074F9),
                                    ),
                                  ),
                                  Text(
                                    '/ ${_globalWalletLimit.toStringAsFixed(2)} FCFA',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: percentageUsed / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentageUsed > 80 ? Colors.red : themeColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${percentageUsed.toStringAsFixed(1)}% utilisé',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: themeColor.withOpacity(0.2), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Solde global',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6074F9)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${totalWithBudgets.toStringAsFixed(2)} FCFA',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: themeColor.withOpacity(0.2), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Limite globale',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6074F9)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${totalExpenseLimit.toStringAsFixed(2)} FCFA',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mes portefeuilles',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6074F9),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'set_global_expense_limit':
                                      _setGlobalExpenseLimit();
                                      break;
                                    case 'add_global_expense_limit':
                                      _addToGlobalExpenseLimit();
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'set_global_expense_limit',
                                    child: Text('Définir limite globale de dépense'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'add_global_expense_limit',
                                    child: Text('Ajouter à la limite globale'),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _wallets.isEmpty && budgetsByName.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.08),
                                            spreadRadius: 1,
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Aucun portefeuille ou budget',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Créez votre premier portefeuille ou budget pour commencer',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _wallets.length,
                                          itemBuilder: (context, index) {
                                            final wallet = _wallets[index];
                                            final expensePercentage = wallet.expenseLimit > 0
                                                ? (wallet.balance / wallet.expenseLimit * 100)
                                                : 0.0;
                                            
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: themeColor.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withOpacity(0.08),
                                                    spreadRadius: 1,
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              wallet.name,
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              '${wallet.balance.toStringAsFixed(2)} FCFA',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                color: themeColor,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuButton<String>(
                                                        onSelected: (value) {
                                                          switch (value) {
                                                            case 'set_expense_limit':
                                                              _setOrUpdateExpenseLimit(wallet);
                                                              break;
                                                            case 'add_expense_limit':
                                                              _addExpenseLimit(wallet);
                                                              break;
                                                            case 'delete':
                                                              _deleteWallet(wallet);
                                                              break;
                                                          }
                                                        },
                                                        itemBuilder: (context) => [
                                                          const PopupMenuItem(
                                                            value: 'set_expense_limit',
                                                            child: Text('Définir limite de dépense'),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: 'add_expense_limit',
                                                            child: Text('Ajouter à la limite'),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text('Supprimer'),
                                                          ),
                                                        ],
                                                        child: Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[100],
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(
                                                            Icons.more_vert,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (wallet.expenseLimit > 0) ...[
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Limite de dépense',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                        Text(
                                                          '${wallet.expenseLimit.toStringAsFixed(2)} FCFA',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    LinearProgressIndicator(
                                                      value: expensePercentage / 100,
                                                      backgroundColor: Colors.grey[300],
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        expensePercentage > 80 ? Colors.red : themeColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${expensePercentage.toStringAsFixed(1)}% utilisé',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        if (budgetsByName.isNotEmpty) ...[
                                          const SizedBox(height: 20),
                                          const Text(
                                            'Mes budgets',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6074F9),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: budgetsByName.length,
                                            itemBuilder: (context, index) {
                                              final budgetSource = budgetsByName.keys.elementAt(index);
                                              final totalAmount = budgetsByName[budgetSource]!;
                                              return _buildBudgetCard(budgetSource, totalAmount);
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transactions récentes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6074F9),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HistoryScreen(),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Voir tout',
                                      style: TextStyle(
                                        color: themeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: themeColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _transactions.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucune transaction',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Vos transactions récentes apparaîtront ici',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _transactions.length,
                                  itemBuilder: (context, index) {
                                    return _buildTransactionCard(_transactions[index]);
                                  },
                                ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen(),
                          ),
                        ).then((_) => _loadData());
                      },
                      backgroundColor: themeColor,
                      heroTag: "add_transaction",
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      onPressed: _navigateToWalletVerification,
                      backgroundColor: themeColor,
                      heroTag: "add_wallet",
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}