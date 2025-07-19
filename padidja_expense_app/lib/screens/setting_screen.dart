import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:padidja_expense_app/providers/theme_provider.dart';
import 'package:padidja_expense_app/screens/user_profil_page.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';
import '../models/user_model.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  final Utilisateur utilisateur;

  const SettingsPage({super.key, required this.utilisateur});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  bool _pushNotifications = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Utilisateur _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.utilisateur;

    // Animation pour le fade-in du contenu
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation pour le slide-up du contenu
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

    // Démarrer les animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Method to navigate to EditProfilePage and handle the returned user
  Future<void> _navigateToEditProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(utilisateur: _currentUser),
      ),
    );

    // Update the current user if the EditProfilePage returns an updated user
    if (updatedUser != null && updatedUser is Utilisateur) {
      setState(() {
        _currentUser = updatedUser;
      });
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
                // Header animé
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
                          'Settings',
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

                // Main content avec animation
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
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(20),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  // Profile Section avec animation retardée
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 1000),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: _buildProfileSection(isDarkMode),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 30),

                                  // Account Settings Section
                                  _buildAnimatedSection(
                                    'Account Settings',
                                    [
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.person_outline_rounded,
                                        title: 'Edit profile',
                                        onTap: _navigateToEditProfile,
                                        showArrow: true,
                                        delay: 200,
                                        isDarkMode: isDarkMode,
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.lock_outline_rounded,
                                        title: 'Change password',
                                        onTap: () {},
                                        showArrow: true,
                                        delay: 300,
                                        isDarkMode: isDarkMode,
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.notifications_outlined,
                                        title: 'Push notifications',
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
                                            activeTrackColor: const Color(0xFF6074F9)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        delay: 400,
                                        isDarkMode: isDarkMode,
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: isDarkMode
                                            ? Icons.light_mode_outlined
                                            : Icons.dark_mode_outlined,
                                        title: 'Dark mode',
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
                                            activeTrackColor: const Color(0xFF6074F9)
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        delay: 500,
                                        isDarkMode: isDarkMode,
                                      ),
                                    ],
                                    isDarkMode: isDarkMode,
                                  ),

                                  const SizedBox(height: 30),

                                  // More Section
                                  _buildAnimatedSection(
                                    'More',
                                    [
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.info_outline_rounded,
                                        title: 'About us',
                                        onTap: () {},
                                        showArrow: true,
                                        delay: 600,
                                        isDarkMode: isDarkMode,
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.privacy_tip_outlined,
                                        title: 'Privacy policy',
                                        onTap: () {},
                                        showArrow: true,
                                        delay: 700,
                                        isDarkMode: isDarkMode,
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

  Widget _buildProfileSection(bool isDarkMode) {
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
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
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
                  colors: [
                    Color(0xFF6074F9),
                    Color(0xFF5A6BF2),
                  ],
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
                  _currentUser.nom,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: const Color(0xFF6074F9).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF6074F9).withValues(alpha: 0.05),
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
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.02),
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
                    color: const Color(0xFF6074F9).withValues(alpha: 0.1),
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
                          color: const Color(0xFF6074F9),
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
                      color: isDarkMode ? Colors.white : Colors.black87,
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
}