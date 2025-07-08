import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../services/wallet_database.dart';
import '../models/transaction.dart' as trans;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class BdaBudgetScreen extends StatefulWidget {
  const BdaBudgetScreen({super.key});

  @override
  State<BdaBudgetScreen> createState() => _BdaBudgetScreenState();
}

class _BdaBudgetScreenState extends State<BdaBudgetScreen> {
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
      final result = await db.query('budgets', where: 'source = ?', whereArgs: ['BDA']);
      setState(() {
        _budgets = result.map((e) => Map<String, dynamic>.from(e)).toList();
        _sortBudgets();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
            compare = a['date'].compareTo(b['date']);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier : $e')),
      );
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.parse(_budgetController.text);
    final category = _categoryController.text.isEmpty ? 'General' : _categoryController.text;
    final name = _nameController.text;
    final description = _descriptionController.text;
    
    final budgetData = {
      'source': 'BDA',
      'amount': amount,
      'category': category,
      'nom': name,
      'description': description,
      'justificatif': _selectedFilePath ?? '',
      'pieceJointe': _selectedFilePath ?? '', // Ajout du champ pieceJointe
      'date': DateTime.now().toIso8601String(),
    };

    try {
      final db = await WalletDatabase.instance.database;
      
      if (_editingBudgetId != null) {
        await db.update('budgets', budgetData, where: 'id = ?', whereArgs: [_editingBudgetId]);
        
        final transaction = trans.Transaction(
          type: 'expense',
          source: 'BDA',
          amount: amount,
          description: 'Modification de budget: $name',
          date: DateTime.now(),
        );
        
        await WalletDatabase.instance.insertTransaction(transaction);
        
        setState(() => _editingBudgetId = null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget modifié avec succès')),
        );
      } else {
        await db.insert('budgets', budgetData);
        
        final transaction = trans.Transaction(
          type: 'income',
          source: 'BDA',
          amount: amount,
          description: 'Ajout de budget: $name (${category})',
          date: DateTime.now(),
        );
        
        await WalletDatabase.instance.insertTransaction(transaction);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget ajouté avec succès')),
        );
      }
      
      _budgetController.clear();
      _categoryController.clear();
      _nameController.clear();
      _descriptionController.clear();
      _justificatifController.clear();
      _selectedFilePath = null;
      
      await _loadBudgets();
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
      );
    }
  }

  Future<void> _editBudget(int id) async {
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
        _selectedFilePath = budget.first['pieceJointe'] as String? ?? '';
      });
      _showAddEditDialog();
    }
  }

  Future<void> _deleteBudget(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce budget ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
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
        
        final budgetDetails = await db.query('budgets', where: 'id = ?', whereArgs: [id], limit: 1);
        
        if (budgetDetails.isNotEmpty) {
          final budget = budgetDetails.first;
          
          final transaction = trans.Transaction(
            type: 'expense',
            source: 'BDA',
            amount: budget['amount'] as double,
            description: 'Suppression de budget: ${budget['nom']} (${budget['category']})',
            date: DateTime.now(),
          );
          
          await WalletDatabase.instance.insertTransaction(transaction);
          
          await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
          
          await _loadBudgets();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget supprimé avec succès')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  void _showAddEditDialog() {
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
                    if (value == null || value.isEmpty) return 'Entrez un nom';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Entrez un montant';
                    if (double.tryParse(value) == null) return 'Montant invalide';
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
              _budgetController.clear();
              _categoryController.clear();
              _nameController.clear();
              _descriptionController.clear();
              _justificatifController.clear();
              _selectedFilePath = null;
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
              Text('Nom: ${budget['nom'] ?? 'Non spécifié'}'),
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
              Text('Date: ${budget['date']}'),
            ],
          ),
        ),
        actions: [
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
    final totalBudget = _budgets.fold(0.0, (sum, b) => sum + (b['amount'] as double));

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
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Budget BDA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        buildNotificationAction(context),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Budget BDA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
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
                            _budgetController.clear();
                            _categoryController.clear();
                            _nameController.clear();
                            _descriptionController.clear();
                            _justificatifController.clear();
                            _selectedFilePath = null;
                            _showAddEditDialog();
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
                            'AJOUTER',
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
                            color: const Color(0xFF6074F9).withValues(alpha: 0.2),
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
                        'Liste des Budgets',
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
                          color: const Color(0xFF6074F9).withValues(alpha: 0.1),
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
          color: const Color(0xFF6074F9).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
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
                    color: const Color(0xFF6074F9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
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
                        budget['nom'] ?? 'Budget sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Montant: ${budget['amount']} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Catégorie: ${budget['category'] ?? 'Non spécifiée'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Date: ${budget['date']}',
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