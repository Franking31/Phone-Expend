import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../widgets/main_drawer_wrapper.dart';
import '../services/wallet_database.dart'; 
import '../models/transaction.dart'; // Import pour le modèle Transaction

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'all'; // Par défaut, affiche tous les types

  // Méthode pour récupérer la somme totale des portefeuilles
  Future<double> _getTotalBalance() async {
    final wallets = await WalletDatabase.instance.getWallets();
    return wallets.fold<double>(0, (sum, w) => sum + w.balance);
  }

  // Méthode pour récupérer les transactions filtrées
  Future<List<Transaction>> _getFilteredTransactions() async {
    final transactions = await WalletDatabase.instance.getLatestTransactions(10); // Limite à 10 pour l'exemple
    if (_selectedType == 'all') return transactions;
    return transactions.where((tx) => tx.type.toLowerCase() == _selectedType.toLowerCase()).toList();
  }

  // Méthode pour calculer la variation hebdomadaire (pourcentage de perte/gain)
  Future<Map<String, double>> _calculateWeeklyVariation() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWeekStart = today.subtract(const Duration(days: 14)); // Début de la semaine il y a 2 semaines
    final thisWeekStart = today.subtract(const Duration(days: 7)); // Début de la semaine dernière

    // Récupérer les transactions des deux dernières semaines
    final allTransactions = await WalletDatabase.instance.getLatestTransactions(1000); // Ajuster selon vos besoins
    final lastWeekTransactions = allTransactions.where((tx) =>
        tx.date.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
        tx.date.isBefore(thisWeekStart.add(const Duration(days: 1))));
    final thisWeekTransactions = allTransactions.where((tx) =>
        tx.date.isAfter(thisWeekStart.subtract(const Duration(days: 1))) &&
        tx.date.isBefore(today.add(const Duration(days: 1))));

    // Calculer les totaux
    final lastWeekTotal = lastWeekTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final thisWeekTotal = thisWeekTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);

    if (lastWeekTotal == 0) return {'variation': 0.0, 'remaining': thisWeekTotal};

    // Calculer la variation en pourcentage
    final variation = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
    final remaining = lastWeekTotal - thisWeekTotal; // Solde restant par rapport à la semaine de départ

    return {'variation': variation, 'remaining': remaining};
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
            double total = snapshot.data ?? 0.0;
            return FutureBuilder<List<Transaction>>(
              future: _getFilteredTransactions(),
              builder: (context, txSnapshot) {
                final transactions = txSnapshot.data ?? [];
                return Column(
                  children: [
                    // Header avec forme arrondie
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
                          // Bouton notification
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
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Contenu déroulant
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _savingsCard(transactions),
                            const SizedBox(height: 15),
                            _savingsCard(transactions),

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
                                      const SizedBox(width: 5),
                                      const Icon(
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

  Widget _savingsCard(List<Transaction> transactions) {
    // Calculer la somme des montants pour les transactions filtrées
    final totalAmount = transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    return FutureBuilder<Map<String, double>>(
      future: _calculateWeeklyVariation(),
      builder: (context, snapshot) {
        final variationData = snapshot.data ?? {'variation': 0.0, 'remaining': 0.0};
        final variation = variationData['variation']!;
        final remaining = variationData['remaining']!;
        final isGain = variation >= 0;

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
                        const Text("Deposit", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text("\$${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Rate", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(
                          "${variation.abs().toStringAsFixed(2)}% ${isGain ? '(Gain)' : '(Perte)'}",
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
                Text(
                  "Solde restant: \$${remaining.toStringAsFixed(2)} ${remaining >= 0 ? '(Économie)' : '(Déficit)'}",
                  style: TextStyle(
                    fontSize: 14,
                    color: remaining >= 0 ? Colors.green : Colors.red,
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
    // Prendre la première transaction disponible (ou une par défaut si aucune)
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction?.description ?? "No transaction",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  transaction?.date.toString() ?? "N/A",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            Text(
              transaction != null ? "${transaction.amount >= 0 ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}" : "0.00",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}