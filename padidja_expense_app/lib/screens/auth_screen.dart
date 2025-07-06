import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF6074F9);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Header bleu avec texte et forme arrondie
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Pour l'espace du status bar
                const Text(
                  'Phone spend',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 32, 
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take your spend in your hands',
                  style: TextStyle(
                    color: Colors.white70, 
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // Toggle Log In / Sign In
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.symmetric(horizontal: 80),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(child: _buildToggleButton("Log in", true, themeColor)),
                Expanded(child: _buildToggleButton("Sign in", false, themeColor)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // Formulaire
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInput("Username or Email", _emailController),
                  const SizedBox(height: 20),
                  _buildInput("Password", _passwordController, isPassword: true),
                  const SizedBox(height: 20),
                  if (!isLogin)
                    Column(
                      children: [
                        _buildInput("Confirm Password", _confirmPasswordController, isPassword: true),
                        const SizedBox(height: 20),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Bouton principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    if (isLogin) {
                      // Exemple temporaire (sans base de données)
                      if (email == "" && password == "") {
                        Navigator.of(context).pushReplacementNamed('/home'); // ✅ navigation
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Email ou mot de passe incorrect")),
                        );
                      }
                    } else {
                      // Sign in : tu peux ajouter une logique d'enregistrement ici
                      if (password == _confirmPasswordController.text.trim()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Compte créé avec succès (fictif)")),
                        );
                        setState(() => isLogin = true); // Retourne à Log in
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
                        );
                      }
                    }
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: themeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                isLogin ? "Log in" : "Sign in",
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "or", 
            style: TextStyle(
              color: Colors.grey, 
              fontSize: 16,
              fontWeight: FontWeight.w400
            )
          ),
          const SizedBox(height: 25),

          // Icônes de réseaux sociaux
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook, const Color(0xFF1877F2)),
              const SizedBox(width: 25),
              _buildSocialIcon(Icons.g_mobiledata, const Color(0xFFDB4437)),
              const SizedBox(width: 25),
              _buildSocialIcon(Icons.close, Colors.black), // X pour Twitter/X
            ],
          ),

          const Spacer(),

          // Mentions légales
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Privacy policy • Terms of service",
              style: TextStyle(
                fontSize: 12, 
                color: Colors.grey,
                fontWeight: FontWeight.w400
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool loginBtn, Color activeColor) {
    final isActive = isLogin == loginBtn;
    return GestureDetector(
      onTap: () => setState(() => isLogin = loginBtn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: const Color(0xFF6074F9), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Ce champ est requis';
          return null;
        },
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon, 
        color: color,
        size: 24,
      ),
    );
  }
}