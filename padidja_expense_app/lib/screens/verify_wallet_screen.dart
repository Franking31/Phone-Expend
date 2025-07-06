import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:padidja_expense_app/screens/minepat_budget_screen.dart';
import 'package:padidja_expense_app/screens/bda_budget_screen.dart';
import 'package:padidja_expense_app/screens/petite_caisse_budget_screen.dart';

class WalletVerificationScreen extends StatefulWidget {
  final double currentTotalBalance;
  final double globalWalletLimit;

  const WalletVerificationScreen({
    Key? key,
    this.currentTotalBalance = 0.0,
    this.globalWalletLimit = double.infinity,
  }) : super(key: key);

  @override
  State<WalletVerificationScreen> createState() => _WalletVerificationScreenState();
}

class _WalletVerificationScreenState extends State<WalletVerificationScreen> {
  final List<PaymentMethod> _paymentSources = [
    PaymentMethod(
      name: 'MINEPAT',
      icon: Icons.work,
      color: Colors.orange,
      type: PaymentType.mobile,
    ),
    PaymentMethod(
      name: 'BDA',
      icon: Icons.business,
      color: Colors.yellow.shade700,
      type: PaymentType.card,
    ),
    PaymentMethod(
      name: 'Petite caisse',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      type: PaymentType.cash,
    ),
  ];

  PaymentMethod? _selectedMethod;

  void _navigateToBudgetScreen() {
    switch (_selectedMethod!.name) {
      case 'MINEPAT':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MinepatBudgetScreen()),
        );
        break;
      case 'BDA':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BdaBudgetScreen()),
        );
        break;
      case 'Petite caisse':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PetiteCaisseBudgetScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choisir une Source',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisissez votre source de dépense',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Sélectionnez la source pour accéder à la liste des budgets',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _paymentSources.length,
                  itemBuilder: (context, index) {
                    final method = _paymentSources[index];
                    final isSelected = _selectedMethod == method;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedMethod = method);
                        _navigateToBudgetScreen();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? method.color : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? method.color.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: isSelected ? 10 : 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: method.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                method.icon,
                                color: method.color,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              method.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? method.color : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PaymentType { mobile, card, cash }

class PaymentMethod {
  final String name;
  final IconData icon;
  final Color color;
  final PaymentType type;

  PaymentMethod({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}