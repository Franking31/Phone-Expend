import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../widgets/main_drawer_wrapper.dart';
import '../services/wallet_database.dart'; 
import '../services/spend_line_database.dart';
import '../models/transaction.dart';
// Removed unused import: '../models/spend_line.dart'

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'all';

  // Méthode pour récupérer la somme totale des portefeuilles
  Future<double> _getTotalBalance() async {
    final wallets = await WalletDatabase.instance.getWallets();
    return wallets.fold<double>(0, (sum, w) => sum + w.balance);
  }

  // Méthode pour récupérer les transactions filtrées
  Future<List<Transaction>> _getFilteredTransactions() async {
    final transactions = await WalletDatabase.instance.getLatestTransactions(10);
    
    if (_selectedType == 'outcome') {
      // Inclure les dépenses des transactions ET des spend_lines
      final spendLines = await SpendLineDatabase.instance.getAll();
      final outcomeTransactions = transactions.where((tx) => tx.type.toLowerCase() == 'outcome').toList();
      
      // Convertir les SpendLine en Transaction pour l'affichage
      final spendLineTransactions = spendLines.take(10 - outcomeTransactions.length).map((spend) =>
        Transaction(
          id: spend.id,
          amount: spend.budget,
          description: spend.description,
          date: spend.date,
          type: 'outcome',
          source: 'spend_line', // Added missing required parameter
        )
      ).toList();
      
      return [...outcomeTransactions, ...spendLineTransactions];
    }
    
    if (_selectedType == 'all') return transactions;
    return transactions.where((tx) => tx.type.toLowerCase() == _selectedType.toLowerCase()).toList();
  }

  // Méthode pour calculer les totaux incluant les spend_lines
  Future<Map<String, double>> _calculateTotals() async {
    final transactions = await WalletDatabase.instance.getLatestTransactions(1000);
    final spendLines = await SpendLineDatabase.instance.getAll();
    
    double totalIncome = 0.0;
    double totalOutcome = 0.0;
    
    // Calculer les revenus et dépenses des transactions
    for (var tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'outcome') {
        totalOutcome += tx.amount;
      }
    }
    
    // Ajouter les dépenses des spend_lines
    for (var spend in spendLines) {
      totalOutcome += spend.budget;
    }
    
    final remaining = totalIncome - totalOutcome;
    final variation = totalIncome > 0 ? ((remaining / totalIncome) * 100) : 0.0;
    
    return {
      'income': totalIncome,
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

  // Méthode pour supprimer un portefeuille et rafraîchir l'état
  Future<void> _deleteWallet(int walletId) async {
    try {
      await WalletDatabase.instance.deleteWallet(walletId);
      if (mounted) { // Added mounted check
        setState(() {});
      }
    } catch (e) {
      if (mounted) { // Added mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la suppression : $e")),
        );
      }
    }
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
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Total Balance",
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
                              _typeButton("Income", _selectedType == 'income'),
                              const SizedBox(width: 15),
                              _typeButton("Outcome", _selectedType == 'outcome'),
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
                            const SizedBox(height: 15),
                            _savingsCard(),
                            const Padding(
                              padding: EdgeInsets.fromLTRB(0, 30, 0, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Latest Transaction",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "See all",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 5), // Removed unnecessary const
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
                            _transactionCard(transactions),
                            const SizedBox(height: 10),
                            _transactionCard(transactions),
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
      onTap: () => _setTransactionType(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
        final totalIncome = totals['income']!;
        final totalOutcome = totals['outcome']!;
        final isGain = remaining >= 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6074F9).withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
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
                  "Savings Account",
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
                        const Text("Revenus", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text("\$${totalIncome.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Dépenses", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text("\$${totalOutcome.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          "\$${remaining.toStringAsFixed(2)}",
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
                    color: isGain ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
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
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4FF),
          border: Border.all(color: const Color(0xFF6074F9).withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
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
                    transaction?.description ?? "Aucune transaction",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction?.date.toString().split(' ')[0] ?? "N/A",
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
                  transaction != null ? "${transaction.amount >= 0 ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}" : "\$0.00",
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
                        ? Colors.red.withValues(alpha: 0.1) 
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction?.type.toUpperCase() ?? "N/A",
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