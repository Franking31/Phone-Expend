import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/wallet_database.dart';
import 'dart:math';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> paymentMethods = ['Orange Money', 'MoMo', 'Carte', 'Caisse'];
  List<bool> _selectedMethods = [false, false, false, false];
  final themeColor = const Color(0xFF6074F9);
  final TextEditingController _cashAmountController = TextEditingController();
  double _plafond = 5000.0; // Plafond fixe initial

  // Simule un solde initial aléatoire (sauf pour Caisse)
  double _simulatedBalance(String method) {
    if (method == 'Caisse') return double.tryParse(_cashAmountController.text) ?? 0.0;
    return Random().nextDouble() * 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // En-tête avec gradient
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const Text(
                          'Ajouter un Portefeuille',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 40), // Placeholder pour alignement
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenu du formulaire
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choisir une méthode de paiement',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(paymentMethods.length, (index) {
                      return CheckboxListTile(
                        title: Text(paymentMethods[index]),
                        value: _selectedMethods[index],
                        onChanged: (bool? value) {
                          setState(() {
                            for (int i = 0; i < _selectedMethods.length; i++) {
                              _selectedMethods[i] = (i == index) ? value! : false;
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                    const SizedBox(height: 20),
                    if (_selectedMethods[3]) // Afficher uniquement pour Caisse
                      Container(
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
                        child: TextFormField(
                          controller: _cashAmountController,
                          decoration: const InputDecoration(
                            hintText: 'Montant initial (FCFA)',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Plafond fixé : 5000 FCFA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
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
                      child: Text(
                        'Solde simulé : ${_simulatedBalance(paymentMethods[_selectedMethods.indexOf(true)]).toStringAsFixed(2)} FCFA',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 120,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          final selectedIndex = _selectedMethods.indexWhere((element) => element);
                          if (selectedIndex != -1) {
                            final selectedMethod = paymentMethods[selectedIndex];
                            final wallet = Wallet(
                              name: selectedMethod,
                              balance: _simulatedBalance(selectedMethod),
                            );
                            // Simuler l'enregistrement
                            await WalletDatabase.instance.insertWallet(wallet);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Portefeuille ajouté ✅')),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez sélectionner une méthode')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'AJOUTER',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}