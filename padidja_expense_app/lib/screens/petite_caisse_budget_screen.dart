import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../services/wallet_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PetiteCaisseBudgetScreen extends StatefulWidget {
  const PetiteCaisseBudgetScreen({super.key});

  @override
  State<PetiteCaisseBudgetScreen> createState() => _PetiteCaisseBudgetScreenState();
}

class _PetiteCaisseBudgetScreenState extends State<PetiteCaisseBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _justificatifController = TextEditingController();
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _filteredBudgets = [];
  bool _isLoading = false;
  int? _editingBudgetId;
  String _sortBy = 'date';
  bool _sortAscending = true;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final db = await WalletDatabase.instance.database;
      final result = await db.query('budgets', where: 'source = ?', whereArgs: ['Petite caisse']);
      setState(() {
        _budgets = result.map((e) => Map<String, dynamic>.from(e)).toList();
        _sortBudgets();
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

  void _sortBudgets() {
    setState(() {
      _filteredBudgets = List.from(_budgets);
      _filteredBudgets.sort((a, b) {
        int compare;
        switch (_sortBy) {
          case 'amount':
            compare = (a['amount'] as double).compareTo(b['amount'] as double);
            break;
          case 'category':
            compare = (a['category'] ?? '').compareTo(b['category'] ?? '');
            break;
          case 'nom':
            compare = (a['nom'] ?? '').compareTo(b['nom'] ?? '');
            break;
          default:
            compare = (a['date'] ?? '').compareTo(b['date'] ?? '');
        }
        return _sortAscending ? compare : -compare;
      });
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _justificatifController.text = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier : $e')),
        );
      }
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amountText = _budgetController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    final category = _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim();
    final budgetName = _nameController.text.trim().isEmpty ? 'Sans nom' : _nameController.text.trim();
    final budgetData = {
      'source': 'Petite caisse',
      'amount': amount,
      'category': category,
      'nom': budgetName,
      'description': _descriptionController.text.trim(),
      'justificatif': _selectedFilePath ?? '',
      'date': DateTime.now().toIso8601String(),
    };

    try {
      final db = await WalletDatabase.instance.database;
      int budgetId;
      if (_editingBudgetId != null) {
        await db.update('budgets', budgetData, where: 'id = ?', whereArgs: [_editingBudgetId]);
        budgetId = _editingBudgetId!;
        setState(() => _editingBudgetId = null);
      } else {
        budgetId = await db.insert('budgets', budgetData);
      }
      
      _clearForm();
      await _loadBudgets();

      final transaction = {
        'type': 'income',
        'source': 'Petite caisse',
        'amount': amount,
        'description': 'Ajout de budget Petite caisse: $budgetName',
        'date': DateTime.now().toIso8601String(),
      };
      final transactionId = await db.insert('transactions', transaction);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget "$budgetName" enregistré avec succès. Transaction ID: $transactionId'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _budgetController.clear();
    _categoryController.clear();
    _nameController.clear();
    _descriptionController.clear();
    _justificatifController.clear();
    _selectedFilePath = null;
  }

  Future<void> _editBudget(int id) async {
    try {
      final db = await WalletDatabase.instance.database;
      final budget = await db.query('budgets', where: 'id = ?', whereArgs: [id], limit: 1);
      if (budget.isNotEmpty) {
        setState(() {
          _editingBudgetId = budget.first['id'] as int;
          _budgetController.text = (budget.first['amount'] as double).toString();
          _categoryController.text = budget.first['category'] as String? ?? '';
          _nameController.text = budget.first['nom'] as String? ?? '';
          _descriptionController.text = budget.first['description'] as String? ?? '';
          _justificatifController.text = budget.first['justificatif'] as String? ?? '';
          _selectedFilePath = budget.first['justificatif'] as String? ?? '';
        });
        _showAddBudgetDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification : $e')),
        );
      }
    }
  }

  Future<void> _deleteBudget(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce budget ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Annuler')
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
        final db = await WalletDatabase.instance.database;
        await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
        await _loadBudgets();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression : $e')),
          );
        }
      }
    }
  }

  Future<void> _shareBudget(Map<String, dynamic> budget) async {
    final budgetText = '''
Budget Petite Caisse Details:
- Name: ${budget['nom'] ?? 'Sans nom'}
- Amount: ${budget['amount']} FCFA
- Category: ${budget['category'] ?? 'Non spécifiée'}
- Description: ${budget['description'] ?? 'Aucune description'}
- Date: ${budget['date']}
${budget['justificatif'] != null && budget['justificatif'].isNotEmpty ? '- Justificatif: ${budget['justificatif'].split('/').last}' : ''}
''';

    try {
      final justificatif = budget['justificatif'] as String?;
      if (justificatif != null && justificatif.isNotEmpty) {
        final file = File(justificatif);
        if (await file.exists()) {
          await Share.shareXFiles(
            [XFile(justificatif)],
            text: budgetText,
            subject: 'Petite Caisse Budget: ${budget['nom'] ?? 'Sans nom'}',
          );
        } else {
          await Share.share(
            budgetText,
            subject: 'Petite Caisse Budget: ${budget['nom'] ?? 'Sans nom'}',
          );
        }
      } else {
        await Share.share(
          budgetText,
          subject: 'Petite Caisse Budget: ${budget['nom'] ?? 'Sans nom'}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
    }
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingBudgetId == null ? 'Ajouter un budget' : 'Modifier le budget'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    border: OutlineInputBorder(),
                    suffixText: 'FCFA',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez un montant';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Montant invalide';
                    }
                    if (double.parse(value.trim()) <= 0) {
                      return 'Le montant doit être positif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _justificatifController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Justificatif (PDF)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickFile,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearForm();
              setState(() => _editingBudgetId = null);
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _saveBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6074F9),
              foregroundColor: Colors.white,
            ),
            child: Text(_editingBudgetId == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDetails(Map<String, dynamic> budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du budget'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nom: ${budget['nom'] ?? 'Sans nom'}'),
              const SizedBox(height: 8),
              Text('Montant: ${budget['amount']} FCFA'),
              const SizedBox(height: 8),
              Text('Catégorie: ${budget['category'] ?? 'Non spécifiée'}'),
              const SizedBox(height: 8),
              Text('Description: ${budget['description'] ?? 'Aucune description'}'),
              const SizedBox(height: 8),
              if (budget['justificatif'] != null && budget['justificatif'].isNotEmpty)
                Text('Justificatif: ${budget['justificatif'].split('/').last}'),
              const SizedBox(height: 8),
              Text('Date: ${budget['date'] ?? 'Non spécifiée'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _shareBudget(budget),
            child: const Text('Partager'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _budgets.fold(0.0, (sum, b) => sum + (b['amount'] as double? ?? 0.0));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            height: 280,
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
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Budget Petite Caisse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        buildNotificationAction(context),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Budget',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalBudget.toStringAsFixed(2)} FCFA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _editingBudgetId = null);
                            _clearForm();
                            _showAddBudgetDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6074F9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'ADD',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF6074F9).withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          onChanged: (String? newValue) {
                            setState(() {
                              _sortBy = newValue!;
                              _sortBudgets();
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'date', child: Text('Date')),
                            DropdownMenuItem(value: 'amount', child: Text('Montant')),
                            DropdownMenuItem(value: 'category', child: Text('Catégorie')),
                            DropdownMenuItem(value: 'nom', child: Text('Nom')),
                          ],
                          underline: Container(),
                        ),
                      ),
                      const SizedBox(width: 15),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                            _sortBudgets();
                          });
                        },
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: const Color(0xFF6074F9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Budget List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6074F9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_filteredBudgets.length}',
                          style: const TextStyle(
                            color: Color(0xFF6074F9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredBudgets.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Aucun budget',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredBudgets.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildBudgetItem(
                                      _filteredBudgets[index],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6074F9).withOpacity(0.2),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBudgetDetails(budget),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6074F9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: Color(0xFF6074F9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget['nom'] ?? 'Sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montant: ${budget['amount'] ?? 0} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Date: ${budget['date'] ?? 'Non spécifiée'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF6074F9)),
                      onPressed: () => _editBudget(budget['id'] as int),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBudget(budget['id'] as int),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _categoryController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _justificatifController.dispose();
    super.dispose();
  }
}