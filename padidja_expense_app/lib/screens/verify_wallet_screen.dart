import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:padidja_expense_app/screens/home_wallet_screen.dart';
import '../models/wallet.dart';
import '../services/wallet_database.dart';

import 'dart:math';

class WalletVerificationScreen extends StatefulWidget {
  const WalletVerificationScreen({Key? key}) : super(key: key);

  @override
  State<WalletVerificationScreen> createState() => _WalletVerificationScreenState();
}

class _WalletVerificationScreenState extends State<WalletVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Méthodes de paiement disponibles
  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      name: 'Orange Money',
      icon: Icons.phone_android,
      color: Colors.orange,
      type: PaymentType.mobile,
    ),
    PaymentMethod(
      name: 'MTN MoMo',
      icon: Icons.smartphone,
      color: Colors.yellow.shade700,
      type: PaymentType.mobile,
    ),
    PaymentMethod(
      name: 'Carte Bancaire',
      icon: Icons.credit_card,
      color: Colors.blue,
      type: PaymentType.card,
    ),
    PaymentMethod(
      name: 'Espèces',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      type: PaymentType.cash,
    ),
  ];

  PaymentMethod? _selectedMethod;
  int _currentStep = 0;
  bool _isProcessing = false;
  double _simulatedBalance = 0.0;
  final double _walletLimit = 5000.0;

  // Contrôleurs pour les champs de saisie
  final Map<String, TextEditingController> _controllers = {
    'phone': TextEditingController(),
    'username': TextEditingController(),
    'pin': TextEditingController(),
    'cardNumber': TextEditingController(),
    'expiryDate': TextEditingController(),
    'cvv': TextEditingController(),
    'cashAmount': TextEditingController(),
  };

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _pageController.dispose();
    super.dispose();
  }

  // Génération du solde simulé
  void _generateBalance() {
    if (_selectedMethod?.type == PaymentType.cash) {
      _simulatedBalance = double.tryParse(_controllers['cashAmount']!.text) ?? 0.0;
    } else {
      // Simulation d'un solde aléatoire pour les autres méthodes
      final random = Random();
      _simulatedBalance = random.nextDouble() * 1500 + 100; // Entre 100 et 1600 FCFA
    }
  }

  // Validation des données selon le type de paiement
  bool _validateCurrentStep() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    switch (_selectedMethod?.type) {
      case PaymentType.mobile:
        return _validateMobilePayment();
      case PaymentType.card:
        return _validateCardPayment();
      case PaymentType.cash:
        return _validateCashPayment();
      default:
        return false;
    }
  }

  bool _validateMobilePayment() {
    final phone = _controllers['phone']!.text.trim();
    final username = _controllers['username']!.text.trim();
    final pin = _controllers['pin']!.text.trim();

    if (phone.isEmpty || username.isEmpty || pin.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return false;
    }

    if (!RegExp(r'^[67]\d{8}$').hasMatch(phone)) {
      _showErrorSnackBar('Numéro de téléphone invalide (doit commencer par 6 ou 7)');
      return false;
    }

    if (username.length < 3) {
      _showErrorSnackBar('Le nom d\'utilisateur doit contenir au moins 3 caractères');
      return false;
    }

    if (pin.length != 4) {
      _showErrorSnackBar('Le code PIN doit contenir exactement 4 chiffres');
      return false;
    }

    return true;
  }

  bool _validateCardPayment() {
    final cardNumber = _controllers['cardNumber']!.text.replaceAll(' ', '').trim();
    final expiryDate = _controllers['expiryDate']!.text.trim();
    final cvv = _controllers['cvv']!.text.trim();

    if (cardNumber.isEmpty || expiryDate.isEmpty || cvv.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs');
      return false;
    }

    if (cardNumber.length != 16) {
      _showErrorSnackBar('Le numéro de carte doit contenir 16 chiffres');
      return false;
    }

    if (!_isValidExpiryDate(expiryDate)) {
      _showErrorSnackBar('Date d\'expiration invalide');
      return false;
    }

    if (cvv.length != 3) {
      _showErrorSnackBar('Le CVV doit contenir 3 chiffres');
      return false;
    }

    return true;
  }

  bool _validateCashPayment() {
    final amountText = _controllers['cashAmount']!.text.trim();
    
    if (amountText.isEmpty) {
      _showErrorSnackBar('Veuillez saisir un montant');
      return false;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Veuillez saisir un montant valide');
      return false;
    }

    if (amount > _walletLimit) {
      _showErrorSnackBar('Le montant ne peut pas dépasser ${_walletLimit.toStringAsFixed(0)} FCFA');
      return false;
    }

    return true;
  }

  bool _isValidExpiryDate(String date) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(date)) return false;
    
    try {
      final parts = date.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      
      if (month < 1 || month > 12) return false;
      
      final now = DateTime.now();
      final expiryDate = DateTime(2000 + year, month + 1, 0); // Dernier jour du mois
      
      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // Formatage automatique du numéro de carte avec validation Luhn basique
  void _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    if (value.length > 16) return;
    
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += value[i];
    }
    
    final selection = _controllers['cardNumber']!.selection;
    _controllers['cardNumber']!.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: math.min(formatted.length, selection.baseOffset + (formatted.length - value.length)),
      ),
    );
  }

  // Formatage automatique de la date d'expiration
  void _formatExpiryDate(String value) {
    if (value.length == 2 && !value.contains('/')) {
      _controllers['expiryDate']!.value = TextEditingValue(
        text: '$value/',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }
  }

  // Navigation entre les étapes
  void _nextStep() {
    // Masquer le clavier
    FocusScope.of(context).unfocus();
    
    if (_currentStep == 0 && _selectedMethod != null) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1 && _validateCurrentStep()) {
      _processVerification();
    }
  }

  void _previousStep() {
    // Masquer le clavier
    FocusScope.of(context).unfocus();
    
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Traitement de la vérification
  Future<void> _processVerification() async {
    setState(() => _isProcessing = true);
    
    try {
      // Simulation d'une vérification réseau
      await Future.delayed(const Duration(seconds: 2));
      
      _generateBalance();
      
      final wallet = Wallet(
        name: _selectedMethod!.name,
        balance: _simulatedBalance,
      );
      
      await WalletDatabase.instance.insertWallet(wallet);
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la vérification: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vérification réussie !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Portefeuille ${_selectedMethod!.name} ajouté',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Solde: ${_simulatedBalance.toStringAsFixed(2)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme le dialogue
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WalletHomeScreen()),
              ); // Navigue vers WalletHomeScreen
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
          onPressed: _isProcessing ? null : () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Ajouter un Portefeuille',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Masquer le clavier en tapant ailleurs
        child: Column(
          children: [
            // Indicateur de progression
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Méthode'),
                  Expanded(child: _buildStepLine(0)),
                  _buildStepIndicator(1, 'Vérification'),
                ],
              ),
            ),
            
            // Contenu principal
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMethodSelection(),
                  _buildVerificationForm(),
                ],
              ),
            ),
            
            // Boutons d'action
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Précédent'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6074F9),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == 0 ? 'Continuer' : 'Vérifier',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6074F9) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 16,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF6074F9) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF6074F9) : Colors.grey[300],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre méthode de paiement',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Sélectionnez la méthode que vous souhaitez ajouter à votre portefeuille',
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
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = _selectedMethod == method;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedMethod = method),
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
    );
  }

  Widget _buildVerificationForm() {
    if (_selectedMethod == null) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vérification ${_selectedMethod!.name}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Saisissez vos informations pour vérifier votre compte',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: _buildFormFields(),
              ),
            ),
            // Informations du portefeuille
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Plafond maximum: ${_walletLimit.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        color: Colors.blue[700],
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
  }

  Widget _buildFormFields() {
    switch (_selectedMethod!.type) {
      case PaymentType.mobile:
        return _buildMobileFields();
      case PaymentType.card:
        return _buildCardFields();
      case PaymentType.cash:
        return _buildCashFields();
    }
  }

  Widget _buildMobileFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _controllers['phone']!,
          label: 'Numéro de téléphone',
          hint: '671234567',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir votre numéro de téléphone';
            }
            if (!RegExp(r'^[67]\d{8}$').hasMatch(value.trim())) {
              return 'Numéro invalide (doit commencer par 6 ou 7)';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _controllers['username']!,
          label: 'Nom d\'utilisateur',
          hint: 'Votre nom d\'utilisateur',
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir votre nom d\'utilisateur';
            }
            if (value.trim().length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _controllers['pin']!,
          label: 'Code PIN',
          hint: '••••',
          obscureText: true,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.lock,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir votre code PIN';
            }
            if (value.trim().length != 4) {
              return 'Le PIN doit contenir exactement 4 chiffres';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _controllers['cardNumber']!,
          label: 'Numéro de carte',
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card,
          onChanged: _formatCardNumber,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir le numéro de carte';
            }
            final cleanNumber = value.replaceAll(' ', '');
            if (cleanNumber.length != 16) {
              return 'Le numéro doit contenir 16 chiffres';
            }
            return null;
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19), // 16 chiffres + 3 espaces
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _controllers['expiryDate']!,
                label: 'Date d\'expiration',
                hint: 'MM/YY',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.date_range,
                onChanged: _formatExpiryDate,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Date requise';
                  }
                  if (!_isValidExpiryDate(value)) {
                    return 'Date invalide';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                controller: _controllers['cvv']!,
                label: 'CVV',
                hint: '123',
                obscureText: true,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.security,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'CVV requis';
                  }
                  if (value.trim().length != 3) {
                    return '3 chiffres requis';
                  }
                  return null;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashFields() {
    return _buildTextField(
      controller: _controllers['cashAmount']!,
      label: 'Montant initial',
      hint: '0',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.attach_money,
      suffix: const Text('FCFA', style: TextStyle(fontWeight: FontWeight.w500)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez saisir un montant';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null || amount <= 0) {
          return 'Montant invalide';
        }
        if (amount > _walletLimit) {
          return 'Maximum: ${_walletLimit.toStringAsFixed(0)} FCFA';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: prefixIcon != null 
                  ? Icon(prefixIcon, color: Colors.grey[600])
                  : null,
              suffix: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Classes auxiliaires
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