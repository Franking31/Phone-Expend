import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';


class SpendLinePage extends StatefulWidget {
  @override
  _SpendLinePageState createState() => _SpendLinePageState();
}

class _SpendLinePageState extends State<SpendLinePage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> spendLines = [
    'Ligne budgétaire',
    'Ligne budgétaire',
    'Ligne budgétaire',
    'Ligne budgétaire',
    'Ligne budgétaire',
    'Ligne budgétaire',
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
                          // Logique d'ajout
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Nouvelle ligne budgétaire ajoutée!',
                              ),
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
                        'Spend line list',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Liste des lignes budgétaires
                    Expanded(
                      child: ListView.builder(
                        itemCount: spendLines.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: _buildSpendLineItem(spendLines[index]),
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

  Widget _buildSpendLineItem(String title) {
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
            // Texte de la ligne budgétaire
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),

            // Icônes d'action
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône d'édition
                GestureDetector(
                  onTap: () {
                    // Action d'édition
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Éditer la ligne budgétaire')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                SizedBox(width: 10),

                // Icône de partage
                GestureDetector(
                  onTap: () {
                    // Action de partage
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Partager la ligne budgétaire')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: Colors.grey[700],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}