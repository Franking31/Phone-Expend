import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import 'package:intl/intl.dart';
import '../widgets/main_drawer_wrapper.dart';
import '../services/wallet_database.dart';
import '../models/transaction.dart' as trans;
import '../services/spend_line_database.dart';


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

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      await WalletDatabase.instance.debugDatabase();
      
      final walletTransactions = await WalletDatabase.instance.getAllTransactions();
      print("Transactions chargées depuis WalletDatabase : ${walletTransactions.length}");
      
      final spendLines = await SpendLineDatabase.instance.getAll();
      print("Dépenses chargées depuis SpendLineDatabase : ${spendLines.length}");
      
      final budgets = await WalletDatabase.instance.getAllBudgets();
      print("Budgets chargés depuis WalletDatabase : ${budgets.length}");
      
      final expenseTransactions = spendLines.map((spendLine) {
        return trans.Transaction(
          id: spendLine.id ?? 0,
          type: 'expense',
          source: spendLine.name,
          amount: spendLine.budget,
          description: spendLine.description,
          date: spendLine.date,
        );
      }).toList();

      final budgetTransactions = budgets.map((budget) {
        DateTime budgetDate;
        if (budget['date'] != null && budget['date'].toString().isNotEmpty) {
          try {
            budgetDate = DateTime.parse(budget['date']);
          } catch (e) {
            budgetDate = DateTime.now();
          }
        } else {
          budgetDate = DateTime.now();
        }

        return trans.Transaction(
          id: budget['id'] ?? 0,
          type: 'budget',
          source: budget['source'] ?? 'Non spécifié',
          amount: (budget['amount'] as num?)?.toDouble() ?? 0.0,
          description: budget['nom'] ?? budget['description'] ?? 'Budget ${budget['category'] ?? 'Non catégorisé'}',
          date: budgetDate,
        );
      }).toList();

      final allTransactions = [...walletTransactions, ...expenseTransactions, ...budgetTransactions];
      
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      setState(() {
        _allTransactions = allTransactions;
        _isLoading = false;
      });
      print("Transactions totales après fusion : ${_allTransactions.length}");
    } catch (e) {
      print("Erreur lors du chargement des transactions : $e");
      setState(() => _isLoading = false);
    }
  }

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
    final theme = Theme.of(context);
    final themeColor = theme.colorScheme.primary;

    return MainDrawerWrapper(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          Text(
                            'Historique',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          buildNotificationAction(context),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
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
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Rechercher...',
                                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.search,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toutes les transactions (${_filteredTransactions.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _loadTransactions,
                        icon: Icon(Icons.refresh, color: themeColor),
                        label: Text('Actualiser', style: TextStyle(color: themeColor)),
                        style: TextButton.styleFrom(
                          foregroundColor: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: themeColor))
                          : _filteredTransactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchTerm.isEmpty 
                                            ? 'Aucune transaction'
                                            : 'Aucune transaction trouvée',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                      if (_searchTerm.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ajoutez des portefeuilles, budgets et effectuez des transactions',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadTransactions,
                                  color: themeColor,
                                  child: ListView.builder(
                                    itemCount: _filteredTransactions.length,
                                    itemBuilder: (context, index) {
                                      final tx = _filteredTransactions[index];
                                      final isIncome = tx.type == 'income';
                                      final isDeletion = tx.type == 'deletion';
                                      final isExpense = tx.type == 'expense';
                                      final isBudget = tx.type == 'budget';
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: themeColor.withOpacity(0.2),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.onSurface.withOpacity(0.08),
                                                spreadRadius: 1,
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isDeletion
                                                      ? Colors.grey.withOpacity(0.1)
                                                      : isIncome
                                                          ? Colors.green.withOpacity(0.1)
                                                          : isExpense
                                                              ? Colors.red.withOpacity(0.1)
                                                              : isBudget
                                                                  ? Colors.blue.withOpacity(0.1)
                                                                  : Colors.grey.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  isDeletion
                                                      ? Icons.delete
                                                      : isIncome
                                                          ? Icons.arrow_downward
                                                          : isExpense
                                                              ? Icons.arrow_upward
                                                              : isBudget
                                                                  ? Icons.account_balance_wallet
                                                                  : Icons.receipt,
                                                  color: isDeletion
                                                      ? Colors.grey
                                                      : isIncome
                                                          ? Colors.green
                                                          : isExpense
                                                              ? Colors.red
                                                              : isBudget
                                                                  ? Colors.blue
                                                                  : Colors.grey,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tx.description,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: theme.colorScheme.onSurface,
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
                                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        Text(
                                                          ' • ',
                                                          style: TextStyle(
                                                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                                                          ),
                                                        ),
                                                        Text(
                                                          _getRelativeDate(tx.date),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          _formatDate(tx.date),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                          ),
                                                        ),
                                                        if (isBudget) ...[
                                                          Text(
                                                            ' • ',
                                                            style: TextStyle(
                                                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: const Text(
                                                              'Budget',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.blue,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    isDeletion 
                                                        ? 'N/A' 
                                                        : isBudget
                                                            ? '${tx.amount.abs().toStringAsFixed(0)}'
                                                            : '${isIncome ? '+' : '-'}${tx.amount.abs().toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDeletion
                                                          ? Colors.grey
                                                          : isIncome
                                                              ? Colors.green
                                                              : isExpense
                                                                  ? Colors.red
                                                                  : isBudget
                                                                      ? Colors.blue
                                                                      : theme.colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    'FCFA',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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