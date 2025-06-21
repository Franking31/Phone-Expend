import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';


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

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF6074F9);

    return MainDrawerWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6074F9),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Le bouton menu est maintenant géré par MainDrawerWrapper
                        const SizedBox(width: 56), // Espace pour le bouton menu du wrapper
                        const Icon(Icons.notifications, color: Colors.white, size: 28),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                "Add Spend Line",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildField("Line Name", _lineNameController),
                          const SizedBox(height: 15),
                          _buildField("Description", _descriptionController),
                          const SizedBox(height: 15),
                          _buildField("Budget", _budgetController, keyboard: TextInputType.number),
                          const SizedBox(height: 15),
                          _buildFieldWithIcon("Proof", _proofController, Icons.download),
                          const SizedBox(height: 15),
                          _buildFieldWithIcon("Time", TextEditingController(text: DateFormat('dd/MM/yyyy').format(_selectedDate)), Icons.calendar_today, onTap: _selectDate),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Spend Line added (fictif) ✅")),
                                );
                              }
                            },
                            child: const Text("ADD", style: TextStyle(fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.pink[50],
      ),
    );
  }

  Widget _buildFieldWithIcon(String label, TextEditingController controller, IconData icon, {VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.pink[50],
        suffixIcon: Icon(icon),
      ),
    );
  }
}