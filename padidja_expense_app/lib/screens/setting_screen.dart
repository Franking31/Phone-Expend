import 'package:flutter/material.dart';
import 'package:padidja_expense_app/widgets/main_drawer_wrapper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  bool _pushNotifications = true;
  bool _darkMode = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
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

  @override
  Widget build(BuildContext context) {
    return MainDrawerWrapper(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6074F9), Color(0xFF5A6BF2)],
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
                        const SizedBox(
                          width: 56,
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 0.5,
                              child: Icon(
                                Icons.settings_rounded,
                                color: Colors.white.withOpacity(value),
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
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
                                          child: _buildProfileSection(),
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
                                        onTap: () {},
                                        showArrow: true,
                                        delay: 200,
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.lock_outline_rounded,
                                        title: 'Change password',
                                        onTap: () {},
                                        showArrow: true,
                                        delay: 300,
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
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        delay: 400,
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.dark_mode_outlined,
                                        title: 'Dark mode',
                                        onTap: () {},
                                        trailing: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: Switch(
                                            key: ValueKey(_darkMode),
                                            value: _darkMode,
                                            onChanged: (value) {
                                              setState(() {
                                                _darkMode = value;
                                              });
                                            },
                                            activeColor: const Color(0xFF6074F9),
                                            activeTrackColor: const Color(0xFF6074F9)
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        delay: 500,
                                      ),
                                    ],
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
                                      ),
                                      _buildAnimatedSettingsItem(
                                        icon: Icons.privacy_tip_outlined,
                                        title: 'Privacy policy',
                                        onTap: () {},
                                        showArrow: true,
                                        delay: 700,
                                      ),
                                    ],
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

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: const Color(0xFF6074F9).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yennefer Doe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'yennefer.doe@email.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: _buildSectionTitle(title),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = false,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: const Color(0xFF6074F9).withOpacity(0.1),
          highlightColor: const Color(0xFF6074F9).withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
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
                    color: const Color(0xFF6074F9).withOpacity(0.1),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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
                            color: Colors.grey[400],
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