import 'package:flutter/material.dart';

class MainDrawerWrapper extends StatefulWidget {
  final Widget child;

  const MainDrawerWrapper({super.key, required this.child});

  @override
  State<MainDrawerWrapper> createState() => _MainDrawerWrapperState();
}

class _MainDrawerWrapperState extends State<MainDrawerWrapper> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _menuButtonFade;
  late Animation<double> _overlayOpacity;

  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _drawerSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: const Offset(0.0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _menuButtonFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _overlayOpacity = Tween<double>(
      begin: 0.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      _isDrawerOpen ? _controller.forward() : _controller.reverse();
    });
  }

  void _navigateTo(String routeName) {
    _toggleDrawer();
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.of(context).pushReplacementNamed(routeName);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Drawer Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6074F9),
                  Color(0xFF5A6BF2),
                ],
              ),
            ),
          ),

          // Main content (slidable)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: _isDrawerOpen ? screenWidth * 0.65 : 0,
            top: _isDrawerOpen ? 60 : 0,
            right: _isDrawerOpen ? -screenWidth * 0.65 : 0,
            bottom: _isDrawerOpen ? 60 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                borderRadius: _isDrawerOpen 
                    ? BorderRadius.circular(20) 
                    : BorderRadius.zero,
                boxShadow: _isDrawerOpen 
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(-5, 0),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  widget.child,
                  // Overlay cliquable quand le drawer est ouvert
                  if (_isDrawerOpen)
                    AnimatedBuilder(
                      animation: _overlayOpacity,
                      builder: (context, child) {
                        return GestureDetector(
                          onTap: _toggleDrawer,
                          child: Container(
                            color: Colors.black.withOpacity(_overlayOpacity.value),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Drawer menu
          SlideTransition(
            position: _drawerSlide,
            child: Container(
              width: screenWidth * 0.75,
              height: screenHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6074F9),
                    Color(0xFF5A6BF2),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Menu bar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Navigation",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu items
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _drawerItem(Icons.home_rounded, "Home", '/home'),
                            _drawerItem(Icons.account_balance_wallet_rounded, "Spend Line", '/spendline'),
                            _drawerItem(Icons.description_rounded, "Spend Form", '/add'),
                            _drawerItem(Icons.bar_chart_rounded, "Graphique", '/stats'),
                            _drawerItem(Icons.history_rounded, "Historique", '/history'),
                            _drawerItem(Icons.wallet_rounded, "Wallets", '/wallets'),
                            _drawerItem(Icons.add_circle_outline_rounded, "Add Wallet", '/addwallet'),
                            _drawerItem(Icons.add_circle_outline_rounded, "Add Transaction", '/addTransaction'),
                             _drawerItem(Icons.add_circle_outline_rounded, "verifyWallet", '/verifyWallet'),
                            _drawerItem(Icons.person_rounded, "User Page", '/userpage'),
                            _drawerItem(Icons.notifications_rounded, "Notification", '/notification'),
                            _drawerItem(Icons.settings_rounded, "Settings", '/settings'),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white24, thickness: 1),
                            const SizedBox(height: 10),
                            _drawerItem(Icons.logout_rounded, "LogOut", '/logout', isLogout: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: FadeTransition(
              opacity: _menuButtonFade,
              child: ScaleTransition(
                scale: _menuButtonFade,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isDrawerOpen ? null : _toggleDrawer,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, String route, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateTo(route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLogout 
                        ? Colors.red.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isLogout ? Colors.red[300] : Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isLogout ? Colors.red[300] : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isLogout 
                      ? Colors.red[300]!.withOpacity(0.6) 
                      : Colors.white.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}