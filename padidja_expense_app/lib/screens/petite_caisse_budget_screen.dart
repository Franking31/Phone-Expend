import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import '../models/screen_type.dart';
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

  // Méthode pour déterminer le type d'écran
  ScreenType _getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenType.mobile;
    if (width < 1200) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  // Méthode pour obtenir les dimensions responsives
  ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final screenType = _getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    switch (screenType) {
      case ScreenType.mobile:
        return ResponsiveDimensions(
          headerHeight: screenHeight * 0.35,
          padding: 16.0,
          cardPadding: 16.0,
          fontSize: 16.0,
          titleFontSize: 18.0,
          headerFontSize: 20.0,
          buttonHeight: 45.0,
          buttonWidth: screenWidth * 0.25,
          maxContentWidth: screenWidth,
          crossAxisCount: 1,
        );
      case ScreenType.tablet:
        return ResponsiveDimensions(
          headerHeight: screenHeight * 0.3,
          padding: 24.0,
          cardPadding: 20.0,
          fontSize: 18.0,
          titleFontSize: 20.0,
          headerFontSize: 24.0,
          buttonHeight: 50.0,
          buttonWidth: 140.0,
          maxContentWidth: screenWidth * 0.9,
          crossAxisCount: 2,
        );
      case ScreenType.desktop:
        return ResponsiveDimensions(
          headerHeight: screenHeight * 0.25,
          padding: 32.0,
          cardPadding: 24.0,
          fontSize: 16.0,
          titleFontSize: 20.0,
          headerFontSize: 28.0,
          buttonHeight: 50.0,
          buttonWidth: 150.0,
          maxContentWidth: 1200.0,
          crossAxisCount: 3,
        );
    }
  }

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
            child: const Text('Annuler'),
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
    final dimensions = _getResponsiveDimensions(context);
    final screenType = _getScreenType(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _editingBudgetId == null ? 'Ajouter un budget' : 'Modifier le budget',
          style: TextStyle(fontSize: dimensions.titleFontSize),
        ),
        content: SizedBox(
          width: screenType == ScreenType.desktop
              ? 500
              : MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    controller: _nameController,
                    label: 'Nom',
                    dimensions: dimensions,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entrez un nom';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: dimensions.padding),
                  _buildFormField(
                    controller: _budgetController,
                    label: 'Montant',
                    dimensions: dimensions,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: 'FCFA',
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
                  SizedBox(height: dimensions.padding),
                  _buildFormField(
                    controller: _categoryController,
                    label: 'Catégorie',
                    dimensions: dimensions,
                  ),
                  SizedBox(height: dimensions.padding),
                  _buildFormField(
                    controller: _descriptionController,
                    label: 'Description',
                    dimensions: dimensions,
                    maxLines: 3,
                  ),
                  SizedBox(height: dimensions.padding),
                  _buildFormField(
                    controller: _justificatifController,
                    label: 'Justificatif (PDF)',
                    dimensions: dimensions,
                    readOnly: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickFile,
                    ),
                  ),
                ],
              ),
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
              minimumSize: Size(dimensions.buttonWidth, dimensions.buttonHeight),
            ),
            child: Text(_editingBudgetId == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required ResponsiveDimensions dimensions,
    TextInputType? keyboardType,
    String? suffixText,
    Widget? suffixIcon,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      style: TextStyle(fontSize: dimensions.fontSize),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.all(dimensions.cardPadding * 0.75),
      ),
      validator: validator,
    );
  }

  void _showBudgetDetails(Map<String, dynamic> budget) {
    final dimensions = _getResponsiveDimensions(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Détails du budget',
          style: TextStyle(fontSize: dimensions.titleFontSize),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nom', budget['nom'] ?? 'Sans nom', dimensions),
              _buildDetailRow('Montant', '${budget['amount']} FCFA', dimensions),
              _buildDetailRow('Catégorie', budget['category'] ?? 'Non spécifiée', dimensions),
              _buildDetailRow('Description', budget['description'] ?? 'Aucune description', dimensions),
              if (budget['justificatif'] != null && budget['justificatif'].isNotEmpty)
                _buildDetailRow('Justificatif', budget['justificatif'].split('/').last, dimensions),
              _buildDetailRow('Date', budget['date'] ?? 'Non spécifiée', dimensions),
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

  Widget _buildDetailRow(String label, String value, ResponsiveDimensions dimensions) {
    return Padding(
      padding: EdgeInsets.only(bottom: dimensions.padding * 0.5),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: dimensions.fontSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final screenType = _getScreenType(context);
    final totalBudget = _budgets.fold(0.0, (sum, b) => sum + (b['amount'] as double? ?? 0.0));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
          child: Column(
            children: [
              _buildHeader(dimensions, totalBudget),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(dimensions.padding),
                  child: Column(
                    children: [
                      _buildControls(dimensions, screenType),
                      SizedBox(height: dimensions.padding),
                      _buildBudgetListHeader(dimensions),
                      SizedBox(height: dimensions.padding),
                      Expanded(
                        child: _buildBudgetList(dimensions, screenType),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveDimensions dimensions, double totalBudget) {
    return Container(
      height: dimensions.headerHeight,
      width: double.infinity,
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
          padding: EdgeInsets.all(dimensions.padding),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Budget Petite Caisse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: dimensions.headerFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  buildNotificationAction(context),
                ],
              ),
              SizedBox(height: dimensions.padding * 1.5),
              Container(
                padding: EdgeInsets.all(dimensions.cardPadding),
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
                    Text(
                      'Total Budget',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: dimensions.fontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: dimensions.padding * 0.5),
                    Text(
                      '${totalBudget.toStringAsFixed(2)} FCFA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dimensions.headerFontSize * 1.4,
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
    );
  }

  Widget _buildControls(ResponsiveDimensions dimensions, ScreenType screenType) {
    return Wrap(
      spacing: dimensions.padding,
      runSpacing: dimensions.padding,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: dimensions.buttonWidth,
          height: dimensions.buttonHeight,
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
            child: Text(
              'ADD',
              style: TextStyle(
                fontSize: dimensions.fontSize * 0.9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          height: dimensions.buttonHeight,
          padding: EdgeInsets.symmetric(horizontal: dimensions.padding * 0.75),
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
    );
  }

  Widget _buildBudgetListHeader(ResponsiveDimensions dimensions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Budget List',
          style: TextStyle(
            fontSize: dimensions.titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: dimensions.padding * 0.75,
            vertical: dimensions.padding * 0.375,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF6074F9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_filteredBudgets.length}',
            style: TextStyle(
              color: const Color(0xFF6074F9),
              fontWeight: FontWeight.bold,
              fontSize: dimensions.fontSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetList(ResponsiveDimensions dimensions, ScreenType screenType) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredBudgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: dimensions.padding),
            Text(
              'Aucun budget',
              style: TextStyle(
                fontSize: dimensions.titleFontSize,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (screenType == ScreenType.desktop && _filteredBudgets.length > 1) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: dimensions.crossAxisCount,
          childAspectRatio: 3.5,
          crossAxisSpacing: dimensions.padding,
          mainAxisSpacing: dimensions.padding,
        ),
        itemCount: _filteredBudgets.length,
        itemBuilder: (context, index) {
          return _buildBudgetItem(_filteredBudgets[index], dimensions);
        },
      );
    }

    return ListView.builder(
      itemCount: _filteredBudgets.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: dimensions.padding * 0.75),
          child: _buildBudgetItem(_filteredBudgets[index], dimensions),
        );
      },
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget, ResponsiveDimensions dimensions) {
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
            padding: EdgeInsets.all(dimensions.cardPadding),
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
                SizedBox(width: dimensions.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget['nom'] ?? 'Sans nom',
                        style: TextStyle(
                          fontSize: dimensions.fontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: dimensions.padding * 0.25),
                      Text(
                        'Montant: ${budget['amount'] ?? 0} FCFA',
                        style: TextStyle(
                          fontSize: dimensions.fontSize * 0.875,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Catégorie: ${budget['category'] ?? 'Non spécifiée'}',
                        style: TextStyle(
                          fontSize: dimensions.fontSize * 0.75,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Date: ${budget['date'] ?? 'Non spécifiée'}',
                        style: TextStyle(
                          fontSize: dimensions.fontSize * 0.75,
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

