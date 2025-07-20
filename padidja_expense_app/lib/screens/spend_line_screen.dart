// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:padidja_expense_app/screens/spend_line_detail_page.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';
import 'add_expense_screen.dart';
import 'edit_spend_line_screen.dart';
import '../models/spend_line.dart';
import '../services/spend_line_database.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class SpendLinePage extends StatefulWidget {
  const SpendLinePage({super.key});

  @override
  State<SpendLinePage> createState() => _SpendLinePageState();
}

class _SpendLinePageState extends State<SpendLinePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<SpendLine> _spendLines = [];
  List<SpendLine> _filteredSpendLines = [];
  bool _isLoading = true;
  String _currentSortOption = 'None';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Calculer le total des budgets
  double get totalBudget {
    return _filteredSpendLines.fold(0.0, (sum, line) => sum + line.budget);
  }

  @override
  void initState() {
    super.initState();
    _loadSpendLines();
    _searchController.addListener(_filterSpendLines);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadSpendLines() async {
    try {
      setState(() => _isLoading = true);
      final lines = await SpendLineDatabase.instance.getAll();
      if (mounted) {
        setState(() {
          _spendLines = lines;
          _filteredSpendLines = lines;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading spend lines: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterSpendLines() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSpendLines = _spendLines.where((line) =>
          line.name.toLowerCase().contains(query) ||
          line.description.toLowerCase().contains(query)).toList();
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_currentSortOption) {
      case 'Budget (Low to High)':
        _filteredSpendLines.sort((a, b) => a.budget.compareTo(b.budget));
        break;
      case 'Budget (High to Low)':
        _filteredSpendLines.sort((a, b) => b.budget.compareTo(a.budget));
        break;
      case 'Name (A-Z)':
        _filteredSpendLines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'Name (Z-A)':
        _filteredSpendLines.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'Date (Newest)':
        _filteredSpendLines.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Date (Oldest)':
        _filteredSpendLines.sort((a, b) => a.date.compareTo(b.date));
        break;
    }
  }

  Future<void> _shareSpendLine(SpendLine line) async {
    final spendLineText = '''
Spend Line Details:
- Name: ${line.name}
- Budget: ${line.budget.toStringAsFixed(2)} FCFA
- Description: ${line.description}
- Date: ${line.date}
${line.proof.isNotEmpty ? '- Proof: ${line.proof.split('/').last}' : ''}
''';

    try {
      if (line.proof.isNotEmpty && await File(line.proof).exists()) {
        await Share.shareXFiles(
          [XFile(line.proof)],
          text: spendLineText,
          subject: 'Spend Line: ${line.name}',
        );
      } else {
        await Share.share(
          spendLineText,
          subject: 'Spend Line: ${line.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing spend line: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSpendLine(SpendLine line) async {
    try {
      await SpendLineDatabase.instance.delete(line.id!);
      _loadSpendLines();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${line.name} deleted successfully'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              // Implement undo functionality if needed
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting spend line: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(SpendLine line) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spend Line'),
        content: Text('Are you sure you want to delete "${line.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSpendLine(line);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('None'),
            _buildSortOption('Budget (Low to High)'),
            _buildSortOption('Budget (High to Low)'),
            _buildSortOption('Name (A-Z)'),
            _buildSortOption('Name (Z-A)'),
            _buildSortOption('Date (Newest)'),
            _buildSortOption('Date (Oldest)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String option) {
    return RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: _currentSortOption,
      onChanged: (value) {
        setState(() {
          _currentSortOption = value!;
          _applySorting();
        });
        Navigator.pop(context);
      },
      activeColor: const Color(0xFF6074F9),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainDrawerWrapper(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Calculer les hauteurs basées sur la taille de l'écran
            final screenHeight = constraints.maxHeight;
            final headerHeight = screenHeight * 0.25; // 25% de la hauteur
            final safeAreaPadding = MediaQuery.of(context).padding.top;
            
            return Column(
              children: [
                // Header avec courbe - hauteur adaptative
                Container(
                  height: headerHeight,
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
                          // Barre de navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              buildNotificationAction(context),
                            ],
                          ),
                          SizedBox(height: headerHeight * 0.15), // Espacement adaptatif
                          // Barre de recherche et filtre
                          Row(
                            children: [
                              // Barre de recherche
                              Expanded(
                                child: Container(
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search a line...',
                                      hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      suffixIcon: _searchController.text.isEmpty
                                          ? const Icon(Icons.search, color: Colors.white, size: 18)
                                          : IconButton(
                                              icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                                              onPressed: () {
                                                _searchController.clear();
                                                _filterSpendLines();
                                              },
                                            ),
                                    ),
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Bouton filtre
                              Container(
                                height: 35,
                                width: 35,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    IconButton(
                                      onPressed: _showFilterDialog,
                                      icon: const Icon(
                                        Icons.tune,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    if (_currentSortOption != 'None')
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Contenu principal - prend le reste de l'espace disponible
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Card avec total des dépenses
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF6074F9),
                                Color(0xFF5A67D8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6074F9).withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total Budget',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
                              const SizedBox(height: 4),
                              Text(
                                '${_filteredSpendLines.length} lignes budgétaires',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bouton ADD
                        SizedBox(
                          width: 120,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddExpenseScreen(),
                                ),
                              );
                              // Recharger après ajout si nécessaire
                              if (result == true) {
                                _loadSpendLines();
                              }
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
                        const SizedBox(height: 20),
                        // Titre de la liste avec compteur et info de tri
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Budget Lines List',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_currentSortOption != 'None')
                                  Text(
                                    'Sorted by: $_currentSortOption',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
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
                                '${_filteredSpendLines.length}',
                                style: const TextStyle(
                                  color: Color(0xFF6074F9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Liste des lignes budgétaires
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6074F9),
                                    ),
                                  ),
                                )
                              : _filteredSpendLines.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchController.text.isEmpty
                                                ? 'No budget lines'
                                                : 'No results found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: RefreshIndicator(
                                        onRefresh: _loadSpendLines,
                                        color: const Color(0xFF6074F9),
                                        child: ListView.builder(
                                          itemCount: _filteredSpendLines.length,
                                          itemBuilder: (context, index) {
                                            return TweenAnimationBuilder<double>(
                                              tween: Tween<double>(begin: 0.0, end: 1.0),
                                              duration: Duration(milliseconds: 300 + (index * 50)),
                                              builder: (context, value, child) {
                                                return Transform.translate(
                                                  offset: Offset(50 * (1 - value), 0),
                                                  child: Opacity(
                                                    opacity: value,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(bottom: 12),
                                                      child: _buildSpendLineItem(
                                                        _filteredSpendLines[index],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpendLineItem(SpendLine line) {
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
        onTap: () {
          // Navigation vers les détails - MODIFIÉ ICI
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpendLineDetailPage(
                spendLine: line,
                primaryColor: const Color(0xFF6074F9),
                heroTag: 'spendline_${line.id ?? 'default'}', // Hero tag unique
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Hero widget pour l'animation - AJOUTÉ
              Hero(
                tag: 'spendline_${line.id ?? 'default'}',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6074F9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF6074F9),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Budget: ${line.budget.toStringAsFixed(2)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (line.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        line.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6074F9)),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditSpendLineScreen(spendLine: line),
                        ),
                      );
                      // Recharger la liste si des modifications ont été effectuées
                      if (result == true) {
                        _loadSpendLines();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF6074F9)),
                    onPressed: () => _shareSpendLine(line),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(line),
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
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}