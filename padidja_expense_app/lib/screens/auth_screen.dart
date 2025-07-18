import 'package:flutter/material.dart';
import '../services/user_service.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Méthode pour gérer les erreurs de manière élégante
  String _getErrorMessage(String error) {
    // Convertir les erreurs techniques en messages user-friendly
    if (error.toLowerCase().contains('network') || error.toLowerCase().contains('connection')) {
      return "Problème de connexion. Vérifiez votre connexion internet.";
    }
    if (error.toLowerCase().contains('timeout')) {
      return "La connexion a pris trop de temps. Veuillez réessayer.";
    }
    if (error.toLowerCase().contains('invalid') || error.toLowerCase().contains('wrong')) {
      return "Identifiants incorrects. Vérifiez vos informations.";
    }
    if (error.toLowerCase().contains('email') && error.toLowerCase().contains('exists')) {
      return "Cette adresse email est déjà utilisée.";
    }
    if (error.toLowerCase().contains('weak') || error.toLowerCase().contains('password')) {
      return "Le mot de passe doit contenir au moins 6 caractères.";
    }
    if (error.toLowerCase().contains('user') && error.toLowerCase().contains('not found')) {
      return "Aucun compte trouvé avec ces informations.";
    }
    
    // Message générique pour les autres erreurs
    return "Une erreur inattendue s'est produite. Veuillez réessayer.";
  }

  // Méthode pour afficher les messages avec style
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  try {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    if (isLogin) {
                      // Connexion
                      final user = await UserService.connecterUtilisateur(email, password);
                      if (user != null) {
                        _showMessage("Connexion réussie ! Bienvenue 👋", isError: false);
                        Navigator.of(context).pushReplacementNamed('/home');
                      } else {
                        _showMessage("Email ou mot de passe incorrect", isError: true);
                      }
                    } else {
                      // Inscription
                      if (password == _confirmPasswordController.text.trim()) {
                        await UserService.inscrireUtilisateur(
                          nom: email.split('@')[0], // Nom temporaire basé sur l'email
                          email: email,
                          motDePasse: password,
                        );
                        _showMessage("Compte créé avec succès ! 🎉", isError: false);
                        setState(() => isLogin = true); // Retourne à Log in
                      } else {
                        _showMessage("Les mots de passe ne correspondent pas", isError: true);
                      }
                    }
                  } catch (e) {
                    // Utiliser notre méthode pour convertir l'erreur
                    _showMessage(_getErrorMessage(e.toString()), isError: true);
                  } finally {
                    setState(() => _isLoading = false);
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
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isLogin ? "Log in" : "Sign in",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w400,
            ),
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
                fontWeight: FontWeight.w400,
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
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
          if (label.toLowerCase().contains('email') && !value.contains('@')) {
            return 'Veuillez saisir une adresse email valide';
          }
          if (label.toLowerCase().contains('password') && value.length < 6) {
            return 'Le mot de passe doit contenir au moins 6 caractères';
          }
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