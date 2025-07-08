import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../widgets/main_drawer_wrapper.dart';
import '../services/wallet_database.dart';
import '../services/spend_line_database.dart';
import '../models/transaction.dart';
import '../models/spend_line.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'all';

  // Modified to include budget amounts in total balance
  Future<double> _getTotalBalance() async {
    final wallets = await WalletDatabase.instance.getWallets();
    final budgets = await WalletDatabase.instance.getAllBudgets();
    final walletBalance = wallets.fold<double>(0, (sum, w) => sum + w.balance);
    final budgetAmount = budgets.fold<double>(0, (sum, b) => sum + (b['amount'] as num).toDouble());
    return walletBalance + budgetAmount;
  }

  // Modified to fetch budget additions or expenses based on type
  Future<List<Transaction>> _getFilteredTransactions() async {
    if (_selectedType == 'income') {
      final budgets = await WalletDatabase.instance.getAllBudgets();
      return budgets.take(2).map((budget) {
        DateTime budgetDate;
        try {
          budgetDate = DateTime.parse(budget['date'] ?? DateTime.now().toIso8601String());
        } catch (e) {
          budgetDate = DateTime.now();
        }
        return Transaction(
          id: budget['id'] ?? 0,
          type: 'income',
          source: budget['source'] ?? 'Non spécifié',
          amount: (budget['amount'] as num?)?.toDouble() ?? 0.0,
          description: budget['nom'] ?? 'Budget ${budget['category'] ?? 'Non catégorisé'}',
          date: budgetDate,
        );
      }).toList();
    } else if (_selectedType == 'outcome') {
      final spendLines = await SpendLineDatabase.instance.getAll();
      return spendLines.take(2).map((spend) => Transaction(
        id: spend.id,
        amount: spend.budget,
        description: spend.description,
        date: spend.date,
        type: 'outcome',
        source: spend.name,
      )).toList();
    } else {
      final budgets = await WalletDatabase.instance.getAllBudgets();
      final spendLines = await SpendLineDatabase.instance.getAll();
      
      final budgetTransactions = budgets.take(2).map((budget) {
        DateTime budgetDate;
        try {
          budgetDate = DateTime.parse(budget['date'] ?? DateTime.now().toIso8601String());
        } catch (e) {
          budgetDate = DateTime.now();
        }
        return Transaction(
          id: budget['id'] ?? 0,
          type: 'income',
          source: budget['source'] ?? 'Non spécifié',
          amount: (budget['amount'] as num?)?.toDouble() ?? 0.0,
          description: budget['nom'] ?? 'Budget ${budget['category'] ?? 'Non catégorisé'}',
          date: budgetDate,
        );
      }).toList();

      final spendTransactions = spendLines.take(2).map((spend) => Transaction(
        id: spend.id,
        amount: spend.budget,
        description: spend.description,
        date: spend.date,
        type: 'outcome',
        source: spend.name,
      )).toList();

      return [...budgetTransactions, ...spendTransactions]
        ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  // Modified to calculate budget and expense totals
  Future<Map<String, double>> _calculateTotals() async {
    final budgets = await WalletDatabase.instance.getAllBudgets();
    final spendLines = await SpendLineDatabase.instance.getAll();
    
    final totalBudget = budgets.fold<double>(0, (sum, b) => sum + (b['amount'] as num).toDouble());
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + (b['spent'] as num? ?? 0.0).toDouble());
    final totalExpenses = spendLines.fold<double>(0, (sum, s) => sum + s.budget);
    
    final totalOutcome = totalSpent + totalExpenses;
    final remaining = totalBudget - totalOutcome;
    final variation = totalBudget > 0 ? ((remaining / totalBudget) * 100) : 0.0;
    
    return {
      'budget': totalBudget,
      'outcome': totalOutcome,
      'variation': variation,
      'remaining': remaining
    };
  }

  void _setTransactionType(String type) {
    setState(() {
      _selectedType = type.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6074F9);

    return MainDrawerWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<double>(
          future: _getTotalBalance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            double total = snapshot.data ?? 0.0;
            return FutureBuilder<List<Transaction>>(
              future: _getFilteredTransactions(),
              builder: (context, txSnapshot) {
                if (!txSnapshot.hasData) return const CircularProgressIndicator();
                final transactions = txSnapshot.data ?? [];
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              buildNotificationAction(context),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Column(
                            children: [
                              Text(
                                '${total.toStringAsFixed(2)} FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Solde total",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _typeButton("Budget", _selectedType == 'income'),
                              const SizedBox(width: 15),
                              _typeButton("Dépenses", _selectedType == 'outcome'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _savingsCard(),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(0, 30, 0, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Derniers mouvements",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Voir tout",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ...transactions.map((tx) => _transactionCard([tx])).toList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _typeButton(String label, bool selected) {
    return GestureDetector(
      onTap: () => _setTransactionType(label == 'Budget' ? 'income' : 'outcome'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF6074F9) : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _savingsCard() {
    return FutureBuilder<Map<String, double>>(
      future: _calculateTotals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final totals = snapshot.data!;
        final remaining = totals['remaining']!;
        final variation = totals['variation']!;
        final totalBudget = totals['budget']!;
        final totalOutcome = totals['outcome']!;
        final isGain = remaining >= 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6074F9).withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Compte d'épargne",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Budget alloué", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text("${totalBudget.toStringAsFixed(0)} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(
                          totalBudget > 0 ? "${((totalBudget / (totalBudget + totalOutcome)) * 100).toStringAsFixed(1)}%" : "0.0%",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Dépenses", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text("${totalOutcome.toStringAsFixed(0)} FCFA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(
                          totalBudget > 0 ? "${((totalOutcome / (totalBudget + totalOutcome)) * 100).toStringAsFixed(1)}%" : "0.0%",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Solde", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(
                          "${remaining.toStringAsFixed(0)} FCFA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isGain ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Taux", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(
                          "${variation.abs().toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isGain ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGain ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isGain ? Icons.trending_up : Icons.trending_down,
                        color: isGain ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isGain ? "Vous économisez de l'argent !" : "Attention, vous êtes en déficit !",
                          style: TextStyle(
                            fontSize: 12,
                            color: isGain ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _transactionCard(List<Transaction> transactions) {
    final transaction = transactions.isNotEmpty ? transactions.first : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4FF),
          border: Border.all(color: const Color(0xFF6074F9).withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction?.description ?? "Aucun mouvement",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction != null
                        ? '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'
                        : "N/A",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction != null
                      ? "${transaction.type == 'income' ? '+' : '-'}${transaction.amount.abs().toStringAsFixed(0)} FCFA"
                      : "0 FCFA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction != null && transaction.type == 'outcome' ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction != null && transaction.type == 'outcome'
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction != null
                        ? (transaction.type == 'income' ? 'BUDGET' : 'DÉPENSE')
                        : "N/A",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: transaction != null && transaction.type == 'outcome' ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}