import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:padidja_expense_app/models/spend_line.dart';
import 'package:padidja_expense_app/services/spend_line_database.dart';
import 'package:padidja_expense_app/services/wallet_database.dart'; // Ajout de l'import pour WalletDatabase
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';
import 'package:padidja_expense_app/widgets/notification_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lineNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _proofController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  List<File> _selectedFiles = [];
  String? _selectedCategory;
  
  // Catégories prédéfinies
  final List<String> _predefinedCategories = [
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingCategories();
  }

  Future<void> _loadExistingCategories() async {
    try {
      final db = await WalletDatabase.instance.database;
      final result = await db.query('budgets', columns: ['category'], distinct: true);
      setState(() {
        // Ajouter les catégories existantes qui ne sont pas déjà dans la liste prédéfinie
        for (var row in result) {
          final category = row['category'] as String?;
          if (category != null && category.isNotEmpty && !_predefinedCategories.contains(category)) {
            _predefinedCategories.add(category);
          }
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sélectionner une catégorie'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _predefinedCategories.length,
              itemBuilder: (context, index) {
                final category = _predefinedCategories[index];
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _categoryController.text = category;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _showCustomCategoryDialog();
                Navigator.pop(context);
              },
              child: const Text('Personnalisé'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomCategoryDialog() {
    final customCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Catégorie personnalisée'),
          content: TextField(
            controller: customCategoryController,
            decoration: const InputDecoration(
              hintText: 'Nom de la catégorie',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final customCategory = customCategoryController.text.trim();
                if (customCategory.isNotEmpty) {
                  setState(() {
                    _selectedCategory = customCategory;
                    _categoryController.text = customCategory;
                    if (!_predefinedCategories.contains(customCategory)) {
                      _predefinedCategories.add(customCategory);
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _selectedFiles.add(File(file.path!));
            }
          }
        });
        _updateProofField();
      }
    } catch (e) {
      print('Erreur file_picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateProofField() {
    if (_selectedFiles.isNotEmpty) {
      _proofController.text = '${_selectedFiles.length} document(s) sélectionné(s)';
    } else {
      _proofController.text = '';
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    _updateProofField();
  }

  void _showFileSelectionOptions() {
    _pickDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF6074F9);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return MainDrawerWrapper(
      child: Builder(
        builder: (innerContext) => Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              // Header avec hauteur flexible
              Container(
                height: screenHeight * 0.25,
                constraints: const BoxConstraints(
                  minHeight: 150,
                  maxHeight: 250,
                ),
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
                    padding: EdgeInsets.all(isTablet ? 30 : 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            buildNotificationAction(innerContext),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(innerContext),
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
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                'Add Spend Line',
                                style: TextStyle(
                                  fontSize: isTablet ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Contenu principal
              Expanded(
                child: Center(
                  child: Container(
                    width: isTablet ? 600 : double.infinity,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 30 : 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField(
                                controller: _lineNameController,
                                hintText: 'Line Name',
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 25 : 20),
                              _buildField(
                                controller: _descriptionController,
                                hintText: 'Description',
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 25 : 20),
                              _buildField(
                                controller: _budgetController,
                                hintText: 'Budget',
                                keyboard: TextInputType.number,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 25 : 20),
                              // Nouveau champ catégorie
                              _buildFieldWithIcon(
                                controller: _categoryController,
                                hintText: 'Catégorie',
                                icon: Icons.category,
                                onTap: _showCategoryDialog,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 25 : 20),
                              _buildFieldWithIcon(
                                controller: _proofController,
                                hintText: 'Ajouter des documents justificatifs',
                                icon: Icons.attach_file,
                                onTap: _showFileSelectionOptions,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 15 : 10),
                              if (_selectedFiles.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF6074F9).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Documents sélectionnés:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTablet ? 18 : 16,
                                        ),
                                      ),
                                      SizedBox(height: isTablet ? 15 : 10),
                                      ...List.generate(_selectedFiles.length, (index) {
                                        final file = _selectedFiles[index];
                                        final fileName = file.path.split('/').last;
                                        final extension = fileName.split('.').last.toLowerCase();
                                        IconData fileIcon;
                                        switch (extension) {
                                          case 'pdf':
                                            fileIcon = Icons.picture_as_pdf;
                                            break;
                                          case 'doc':
                                          case 'docx':
                                            fileIcon = Icons.description;
                                            break;
                                          case 'xlsx':
                                          case 'xls':
                                            fileIcon = Icons.table_chart;
                                            break;
                                          case 'txt':
                                            fileIcon = Icons.text_snippet;
                                            break;
                                          default:
                                            fileIcon = Icons.insert_drive_file;
                                        }
                                        return Container(
                                          margin: EdgeInsets.only(bottom: isTablet ? 10 : 8),
                                          padding: EdgeInsets.all(isTablet ? 16 : 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                fileIcon,
                                                color: const Color(0xFF6074F9),
                                                size: isTablet ? 24 : 20,
                                              ),
                                              SizedBox(width: isTablet ? 15 : 10),
                                              Expanded(
                                                child: Text(
                                                  fileName,
                                                  style: TextStyle(
                                                    fontSize: isTablet ? 16 : 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                  size: isTablet ? 24 : 20,
                                                ),
                                                onPressed: () => _removeFile(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              SizedBox(height: isTablet ? 25 : 20),
                              _buildFieldWithIcon(
                                controller: TextEditingController(
                                  text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                                ),
                                hintText: 'Time',
                                icon: Icons.calendar_today,
                                onTap: _selectDate,
                                isTablet: isTablet,
                              ),
                              SizedBox(height: isTablet ? 50 : 40),
                              // Bouton responsive
                              Center(
                                child: SizedBox(
                                  width: isTablet ? 150 : 120,
                                  height: isTablet ? 55 : 45,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        if (_formKey.currentState!.validate()) {
                                          List<String> filePaths = _selectedFiles.map((file) => file.path).toList();
                                          final line = SpendLine(
                                            name: _lineNameController.text.trim(),
                                            description: _descriptionController.text.trim(),
                                            budget: double.tryParse(_budgetController.text) ?? 0,
                                            proof: filePaths.join(';'),
                                            date: _selectedDate,
                                            category: _selectedCategory ?? 'Autre', // Ajout de la catégorie
                                          );
                                          print("Tentative d'insertion: $line");
                                          await SpendLineDatabase.instance.insert(line);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(innerContext).showSnackBar(
                                            const SnackBar(content: Text('Ligne de dépense ajoutée ✅')),
                                          );
                                          Navigator.pop(innerContext, true);
                                        }
                                      } catch (e) {
                                        print("Erreur lors de l'insertion: $e");
                                        if (mounted) {
                                          ScaffoldMessenger.of(innerContext).showSnackBar(
                                            SnackBar(
                                              content: Text('Erreur: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
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
                                    child: Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboard = TextInputType.text,
    bool isTablet = false,
  }) {
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: isTablet ? 18 : 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 25 : 20,
            vertical: isTablet ? 20 : 15,
          ),
        ),
        style: TextStyle(fontSize: isTablet ? 18 : 16),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFieldWithIcon({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    VoidCallback? onTap,
    bool isTablet = false,
  }) {
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
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: isTablet ? 18 : 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 25 : 20,
            vertical: isTablet ? 20 : 15,
          ),
          suffixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: isTablet ? 24 : 20,
          ),
        ),
        style: TextStyle(fontSize: isTablet ? 18 : 16),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _lineNameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _proofController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}