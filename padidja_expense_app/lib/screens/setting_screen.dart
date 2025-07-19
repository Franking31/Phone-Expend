import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:padidja_expense_app/providers/theme_provider.dart';
import 'package:padidja_expense_app/screens/user_profil_page.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserDataManager {
  // Méthode pour récupérer l'utilisateur depuis SharedPreferences
  static Future<Utilisateur?> getUserFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final userId = prefs.getString('current_user_id');
      
      if (userData != null) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        return Utilisateur.fromMap(userMap);
      }
      
      return null;
    } catch (e) {
      print('Erreur SharedPreferences: $e');
      return null;
    }
  }

  // Sauvegarder dans SharedPreferences
  static Future<void> saveUserToPreferences(Utilisateur user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toMap()));
      await prefs.setString('current_user_id', user.id); // Changé de userId à id
      print('✅ Utilisateur sauvegardé dans SharedPreferences');
    } catch (e) {
      print('Erreur sauvegarde SharedPreferences: $e');
    }
  }

  // Nettoyer les données sauvegardées
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('current_user_id');
      print('✅ Données utilisateur nettoyées');
    } catch (e) {
      print('Erreur nettoyage: $e');
    }
  }
}

class SettingsPage extends StatefulWidget {
  final Utilisateur utilisateur;

  const SettingsPage({super.key, required this.utilisateur});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  bool _pushNotifications = true;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Utilisateur _currentUser;

  @override
  void initState() {
    super.initState();
    
    print('=== DÉBUT INITIALISATION SettingsPage ===');
    print('Données utilisateur reçues en paramètre:');
    print('- Nom: "${widget.utilisateur.nom}"');
    print('- Email: "${widget.utilisateur.email}"');
    print('- Role: "${widget.utilisateur.role}"');
    print('- ImagePath: "${widget.utilisateur.imagePath ?? 'null'}"');
    
    _currentUser = widget.utilisateur;
    
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🔄 Chargement des données utilisateur depuis SharedPreferences...');
      
      final localUser = await UserDataManager.getUserFromPreferences();
      
      if (localUser != null && mounted) {
        print('✅ Utilisateur trouvé via SharedPreferences:');
        print('- Nom: "${localUser.nom}"');
        print('- Email: "${localUser.email}"');
        print('- Role: "${localUser.role}"');
        
        setState(() {
          _currentUser = localUser;
        });
      } else {
        print('❌ Aucun utilisateur trouvé dans SharedPreferences');
        
        if (widget.utilisateur.nom.isNotEmpty && 
            widget.utilisateur.email.isNotEmpty) {
          print('✅ Utilisation des données du widget (fallback):');
          print('- Nom: "${widget.utilisateur.nom}"');
          print('- Email: "${widget.utilisateur.email}"');
          
          setState(() {
            _currentUser = widget.utilisateur;
          });
          
          await UserDataManager.saveUserToPreferences(widget.utilisateur);
        } else {
          print('❌ Données du widget invalides');
          _showNoUserDialog();
        }
      }
      
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      if (widget.utilisateur.nom.isNotEmpty && 
          widget.utilisateur.email.isNotEmpty && mounted) {
        setState(() {
          _currentUser = widget.utilisateur;
        });
      } else {
        _showNoUserDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('=== FIN CHARGEMENT ===');
      print('Données finales:');
      print('- Nom: "${_currentUser.nom}"');
      print('- Email: "${_currentUser.email}"');
      print('- Role: "${_currentUser.role}"');
    }
  }

  void _showNoUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session expirée'),
        content: const Text(
          'Impossible de récupérer vos données utilisateur. '
          'Veuillez vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Se reconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _navigateToEditProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(utilisateur: _currentUser),
      ),
    );

    if (updatedUser != null && updatedUser is Utilisateur && mounted) {
      print('✅ Utilisateur mis à jour:');
      print('- Nouveau nom: "${updatedUser.nom}"');
      print('- Nouveau email: "${updatedUser.email}"');
      
      setState(() {
        _currentUser = updatedUser;
      });
      
      await UserDataManager.saveUserToPreferences(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return MainDrawerWrapper(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [const Color(0xFF2E2E2E), const Color(0xFF1E1E1E)]
                  : [const Color(0xFF6074F9), const Color(0xFF5A6BF2)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 56),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 0.5,
                              child: Icon(
                                Icons.settings_rounded,
                                color: Colors.white.withValues(alpha: value),
                                size: 28,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Paramètres',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? _buildLoadingIndicator()
                            : CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.all(20),
                                    sliver: SliverList(
                                      delegate: SliverChildListDelegate([
                                        _buildProfileSection(isDarkMode),
                                        const SizedBox(height: 30),
                                        _buildAnimatedSection(
                                          'Paramètres du compte',
                                          [
                                            _buildAnimatedSettingsItem(
                                              icon: Icons.person_outline_rounded,
                                              title: 'Modifier le profil',
                                              onTap: _navigateToEditProfile,
                                              showArrow: true,
                                              delay: 200,
                                              isDarkMode: isDarkMode,
                                            ),
                                            _buildAnimatedSettingsItem(
                                              icon: Icons.lock_outline_rounded,
                                              title: 'Changer le mot de passe',
                                              onTap: () {},
                                              showArrow: true,
                                              delay: 300,
                                              isDarkMode: isDarkMode,
                                            ),
                                            _buildAnimatedSettingsItem(
                                              icon: Icons.notifications_outlined,
                                              title: 'Notifications push',
                                              onTap: () {},
                                              trailing: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: Switch(
                                                  key: ValueKey(_pushNotifications),
                                                  value: _pushNotifications,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _pushNotifications = value;
                                                    });
                                                  },
                                                  activeColor: const Color(0xFF6074F9),
                                                  activeTrackColor: const Color(0xFF6074F9).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              delay: 400,
                                              isDarkMode: isDarkMode,
                                            ),
                                            _buildAnimatedSettingsItem(
                                              icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                              title: 'Mode sombre',
                                              onTap: () {},
                                              trailing: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: Switch(
                                                  key: ValueKey(isDarkMode),
                                                  value: isDarkMode,
                                                  onChanged: (value) {
                                                    themeProvider.toggleTheme();
                                                  },
                                                  activeColor: const Color(0xFF6074F9),
                                                  activeTrackColor: const Color(0xFF6074F9).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              delay: 500,
                                              isDarkMode: isDarkMode,
                                            ),
                                          ],
                                          isDarkMode: isDarkMode,
                                        ),
                                        const SizedBox(height: 30),
                                        _buildAnimatedSection(
                                          'Plus d\'options',
                                          [
                                            _buildAnimatedSettingsItem(
                                              icon: Icons.info_outline_rounded,
                                              title: 'À propos de nous',
                                              onTap: () {},
                                              showArrow: true,
                                              delay: 600,
                                              isDarkMode: isDarkMode,
                                            ),
                                            _buildAnimatedSettingsItem(
                                              icon: Icons.privacy_tip_outlined,
                                              title: 'Politique de confidentialité',
                                              onTap: () {},
                                              showArrow: true,
                                              delay: 700,
                                              isDarkMode: isDarkMode,
                                            ),
                                            _buildAnimatedSettingsItem(
                                              icon: Icons.logout_rounded,
                                              title: 'Se déconnecter',
                                              onTap: _showLogoutDialog,
                                              showArrow: true,
                                              delay: 800,
                                              isDarkMode: isDarkMode,
                                              isDestructive: true,
                                            ),
                                          ],
                                          isDarkMode: isDarkMode,
                                        ),
                                        const SizedBox(height: 20),
                                      ]),
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
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6074F9)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des informations...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDarkMode) {
    print('=== AFFICHAGE PROFIL ===');
    print('Nom à afficher: "${_currentUser.nom}"');
    print('Email à afficher: "${_currentUser.email}"');
    print('Role à afficher: "${_currentUser.role}"');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2E2E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6074F9), Color(0xFF5A6BF2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6074F9).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _currentUser.imagePath != null && 
                     _currentUser.imagePath!.isNotEmpty && 
                     File(_currentUser.imagePath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.file(
                        File(_currentUser.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser.nom.trim().isNotEmpty ? _currentUser.nom.trim() : 'Nom non disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser.email.trim().isNotEmpty ? _currentUser.email.trim() : 'Email non disponible',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6074F9).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentUser.role.trim().isNotEmpty ? _currentUser.role.toUpperCase() : 'ROLE INCONNU',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6074F9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              print('=== ACTUALISATION MANUELLE ===');
              _loadUserData();
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            tooltip: 'Actualiser les informations',
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(String title, List<Widget> items, {bool isDarkMode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: _buildSectionTitle(title, isDarkMode),
            );
          },
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildAnimatedSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = false,
    Widget? trailing,
    int delay = 0,
    bool isDarkMode = false,
    bool isDestructive = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: _buildSettingsItem(
              icon: icon,
              title: title,
              onTap: onTap,
              showArrow: showArrow,
              trailing: trailing,
              isDarkMode: isDarkMode,
              isDestructive: isDestructive,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = false,
    Widget? trailing,
    bool isDarkMode = false,
    bool isDestructive = false,
  }) {
    final Color iconColor = isDestructive ? Colors.red : const Color(0xFF6074F9);
    final Color textColor = isDestructive 
        ? Colors.red 
        : (isDarkMode ? Colors.white : Colors.black87);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: iconColor.withValues(alpha: 0.1),
          highlightColor: iconColor.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2E2E2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF404040) : Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
                if (showArrow)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(5 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await UserDataManager.clearUserData();
                  await UserService.deconnexion();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la déconnexion: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}