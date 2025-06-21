import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  @override
  _UserFormPageState createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'Role';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header avec courbe bleue
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A90E2),
                  Color(0xFF357ABD),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu hamburger
                    Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 28,
                    ),
                    // Notification bell
                    Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu du formulaire
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bouton retour et titre
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'Add User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Champ Username
                        _buildTextField(
                          controller: _usernameController,
                          hintText: 'Username',
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Champ Email
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email',
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Dropdown Role
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Color(0xFF4A90E2), width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              hint: Text(
                                'Role',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              items: ['Role', 'Admin', 'User', 'Manager'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: value == 'Role' ? Colors.grey[600] : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue!;
                                });
                              },
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Champ Password
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          isPassword: true,
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Champ Confirm Password
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          isPassword: true,
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Bouton ADD
                        Container(
                          width: 120,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Logique d'ajout d'utilisateur
                              if (_formKey.currentState!.validate()) {
                                // Traitement du formulaire
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Utilisateur ajouté avec succès!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4A90E2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              'ADD',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Color(0xFF4A90E2), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}