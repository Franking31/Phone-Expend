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
  final themeColor = const Color(0xFF6074F9);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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


// Dans WalletHomeScreen, remplacez la méthode _navigateToWalletVerification par :

// Voici la version corrigée avec plus de debug pour identifier le problème

Future<void> _navigateToWalletVerification() async {
  print("🚀 Navigation vers WalletVerificationScreen");
  
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WalletVerificationScreen()),
  );
  
  print("🔄 Retour de WalletVerificationScreen avec result: $result");
  
  if (result == true && mounted) {
    print("✅ Result est true et widget est mounted");
    
    try {
      // Recharger d'abord les données
      print("📂 Rechargement des données...");
      await _loadData();
      
      // Récupérer tous les portefeuilles
      final wallets = await WalletDatabase.instance.getWallets();
      print("💼 Portefeuilles récupérés: ${wallets.length}");
      
      if (wallets.isNotEmpty) {
        final newWallet = wallets.last;
        print("🆕 Nouveau portefeuille: ${newWallet.name} avec balance ${newWallet.balance}");
        
        // Vérifier si une transaction existe déjà pour ce portefeuille
        final existingTransactions = await WalletDatabase.instance.getAllTransactions();
        final walletCreationTx = existingTransactions.where(
          (tx) => tx.description.contains('Ajout de portefeuille: ${newWallet.name}')
        ).toList();
        
        print("🔍 Transactions existantes pour ce portefeuille: ${walletCreationTx.length}");
        
        if (walletCreationTx.isEmpty) {
          // Créer la transaction d'ajout de portefeuille
          final transaction = Transaction(
            type: 'income',
            amount: newWallet.balance,
            description: 'Ajout de portefeuille: ${newWallet.name}',
            date: DateTime.now(),
            source: newWallet.name,
          );
          
          print("💰 Création de la transaction: ${transaction.toMap()}");
          
          // Insérer directement dans la base sans mise à jour du solde
          final db = await WalletDatabase.instance.database;
          final txMap = transaction.toMap();
          txMap['date'] = DateTime.now().toIso8601String();
          
          print("📝 Insertion directe dans la DB: $txMap");
          
          final id = await db.insert('transactions', txMap);
          print("✅ Transaction insérée avec ID: $id");
          
          // Vérifier que la transaction a bien été insérée
          final allTx = await db.query('transactions');
          print("🔄 Toutes les transactions après insertion: $allTx");
          
          // Recharger les données
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

  @override
  Widget build(BuildContext context) {
    final total = _wallets.fold<double>(0, (sum, w) => sum + w.balance);

    return MainDrawerWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6074F9), Color(0xFF6074F9)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                                  color: Colors.white,
                                ),
                              ),
                              buildNotificationAction(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
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
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${total.toStringAsFixed(2)} FCFA',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Portefeuilles',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: _navigateToWalletVerification,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Ajouter'),
                              style: TextButton.styleFrom(foregroundColor: themeColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_wallets.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
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
                                  'Aucun portefeuille',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajoutez votre premier portefeuille pour commencer',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _navigateToWalletVerification,
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text(
                                    'Ajouter un portefeuille',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._wallets.map((w) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getWalletColor(w.name).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getWalletIcon(w.name),
                                    color: _getWalletColor(w.name),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${w.balance.toStringAsFixed(2)} FCFA',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _deleteWallet(w);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        const SizedBox(height: 20),
                        const Text(
                          'Dernières transactions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        if (_transactions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucune transaction',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._transactions.map((t) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${t.type.toUpperCase()}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${t.source} • ${t.description}',
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${t.date.day}/${t.date.month}/${t.date.year}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'wallet',
                        onPressed: _navigateToWalletVerification,
                        backgroundColor: themeColor,
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      FloatingActionButton(
                        heroTag: 'transaction',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                        ).then((_) => _loadData()),
                        backgroundColor: themeColor,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6074F9)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getWalletIcon(String walletName) {
    switch (walletName.toLowerCase()) {
      case 'orange money':
        return Icons.phone_android;
      case 'mtn momo':
        return Icons.smartphone;
      case 'carte bancaire':
        return Icons.credit_card;
      case 'espèces':
        return Icons.account_balance_wallet;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getWalletColor(String walletName) {
    switch (walletName.toLowerCase()) {
      case 'orange money':
        return Colors.orange;
      case 'mtn momo':
        return Colors.yellow.shade700;
      case 'carte bancaire':
        return Colors.blue;
      case 'espèces':
        return Colors.green;
      default:
        return themeColor;
    }
  }
}