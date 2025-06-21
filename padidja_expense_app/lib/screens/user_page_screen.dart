import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';


class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> users = [
    'User',
    'User',
    'User',
    'User',
    'User',
    'User',
    'User',
  ];

  @override
  Widget build(BuildContext context) {
    return MainDrawerWrapper(
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Column(
          children: [
            // Header avec courbe bleue
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Barre de navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Notification bell
                          Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),

                      SizedBox(height: 30),

                      // Barre de recherche et filtre
                      Row(
                        children: [
                          // Barre de recherche
                          Expanded(
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: '',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          SizedBox(width: 15),

                          // Bouton filtre
                          Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 20,
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
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Bouton ADD
                    Container(
                      width: 120,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigation vers la page d'ajout d'utilisateur
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ajouter un nouvel utilisateur'),
                            ),
                          );
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

                    SizedBox(height: 25),

                    // Titre de la liste
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'User list',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Liste des utilisateurs
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: _buildUserItem(users[index]),
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
      ),
    );
  }

  Widget _buildUserItem(String userName) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Texte utilisateur
            Expanded(
              child: Text(
                userName,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),

            // Icône d'édition
            GestureDetector(
              onTap: () {
                // Action d'édition de l'utilisateur
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Éditer l\'utilisateur: $userName')),
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.edit_outlined,
                  size: 22,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}