import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:padidja_expense_app/models/spend_line.dart';
import 'package:padidja_expense_app/services/spend_line_database.dart';
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
  DateTime _selectedDate = DateTime.now();
  
  List<File> _selectedFiles = [];

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

    return MainDrawerWrapper(
      child: Builder(
        builder: (innerContext) => Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            buildNotificationAction(innerContext),
                          ],
                        ),
                        const SizedBox(height: 30),
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
                            const Text(
                              'Add Spend Line',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            controller: _lineNameController,
                            hintText: 'Line Name',
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            controller: _descriptionController,
                            hintText: 'Description',
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            controller: _budgetController,
                            hintText: 'Budget',
                            keyboard: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _buildFieldWithIcon(
                            controller: _proofController,
                            hintText: 'Ajouter des documents justificatifs',
                            icon: Icons.attach_file,
                            onTap: _showFileSelectionOptions,
                          ),
                          const SizedBox(height: 10),
                          if (_selectedFiles.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                  const Text(
                                    'Documents sélectionnés:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
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
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              fileName,
                                              style: const TextStyle(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                            onPressed: () => _removeFile(index),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          _buildFieldWithIcon(
                            controller: TextEditingController(
                              text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                            ),
                            hintText: 'Time',
                            icon: Icons.calendar_today,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 120,
                            height: 45,
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
                                    );
                                    print("Tentative d'insertion: $line");
                                    await SpendLineDatabase.instance.insert(line);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(innerContext).showSnackBar(
                                      const SnackBar(content: Text('Ligne de dépense ajoutée ✅')),
                                    );
                                    // Retourner true pour indiquer que la dépense a été ajoutée
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
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
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
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: Icon(icon, color: Colors.grey[600]),
        ),
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
    super.dispose();
  }
}