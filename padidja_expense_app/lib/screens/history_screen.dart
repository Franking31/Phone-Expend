import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import 'package:intl/intl.dart'; // Ajoutez cette dépendance dans pubspec.yaml
import '../widgets/main_drawer_wrapper.dart';
import '../services/wallet_database.dart';
import '../models/transaction.dart' as trans;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchTerm = "";
  List<trans.Transaction> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // Méthode pour formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "Aujourd'hui à ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays == 1) {
      return "Hier à ${DateFormat('HH:mm').format(date)}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} jours";
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // Méthode pour obtenir la date relative
  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} jours";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? "Il y a 1 semaine" : "Il y a $weeks semaines";
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? "Il y a 1 mois" : "Il y a $months mois";
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? "Il y a 1 an" : "Il y a $years ans";
    }
  }

  // Méthode pour charger les transactions
  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      // Déboguer la base de données
      await WalletDatabase.instance.debugDatabase();
      
      // Récupérer toutes les transactions
      final transactions = await WalletDatabase.instance.getAllTransactions();
      print("Transactions chargées dans HistoryScreen : ${transactions.length}");
      
      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des transactions : $e");
      setState(() => _isLoading = false);
    }
  }

  // Méthode pour filtrer les transactions
  List<trans.Transaction> get _filteredTransactions {
    if (_searchTerm.isEmpty) {
      return _allTransactions;
    }
    
    return _allTransactions.where((tx) =>
        tx.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
        tx.source.toLowerCase().contains(_searchTerm.toLowerCase()) ||
        tx.type.toLowerCase().contains(_searchTerm.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF6074F9);

    return MainDrawerWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header avec fond bleu
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF6074F9),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Barre de navigation supérieure
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          const Text(
                            'Historique',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          buildNotificationAction(context),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Barre de recherche
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchTerm = value;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Rechercher...',
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.search,
                                color: Colors.black54,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Contenu principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre sans flèche de retour
                    Text(
                      'Toutes les transactions (${_filteredTransactions.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bouton de rafraîchissement
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _loadTransactions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                        style: TextButton.styleFrom(
                          foregroundColor: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Liste des transactions
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredTransactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchTerm.isEmpty 
                                            ? 'Aucune transaction'
                                            : 'Aucune transaction trouvée',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_searchTerm.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ajoutez des portefeuilles et effectuez des transactions',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadTransactions,
                                  child: ListView.builder(
                                    itemCount: _filteredTransactions.length,
                                    itemBuilder: (context, index) {
                                      final tx = _filteredTransactions[index];
                                      final isIncome = tx.type == 'income';
                                      final isDeletion = tx.type == 'deletion';
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: themeColor.withOpacity(0.2),
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
                                          child: Row(
                                            children: [
                                              // Icône de transaction
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isDeletion
                                                      ? Colors.grey.withOpacity(0.1)
                                                      : isIncome
                                                          ? Colors.green.withOpacity(0.1)
                                                          : Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  isDeletion
                                                      ? Icons.delete
                                                      : isIncome
                                                          ? Icons.arrow_downward
                                                          : Icons.arrow_upward,
                                                  color: isDeletion
                                                      ? Colors.grey
                                                      : isIncome
                                                          ? Colors.green
                                                          : Colors.red,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Détails de la transaction
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tx.description,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          tx.source,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        Text(
                                                          ' • ',
                                                          style: TextStyle(
                                                            color: Colors.grey[400],
                                                          ),
                                                        ),
                                                        Text(
                                                          _getRelativeDate(tx.date),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    // Date complète en petit
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _formatDate(tx.date),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Montant
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    isDeletion ? 'N/A' : '${isIncome ? '+' : '-'}${tx.amount.abs().toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDeletion
                                                          ? Colors.grey
                                                          : isIncome
                                                              ? Colors.green
                                                              : Colors.red,
                                                    ),
                                                  ),
                                                  const Text(
                                                    'FCFA',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}