import 'package:flutter/material.dart';

class MainDrawerWrapper extends StatefulWidget {
  final Widget child;

  const MainDrawerWrapper({super.key, required this.child});

  @override
  State<MainDrawerWrapper> createState() => _MainDrawerWrapperState();
}

class _MainDrawerWrapperState extends State<MainDrawerWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _menuButtonFade;

  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _drawerSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: const Offset(0.0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _menuButtonFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
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
    Future.delayed(const Duration(milliseconds: 250), () {
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

    return Stack(
      children: [
        // Main content (slidable)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: _isDrawerOpen ? screenWidth * 0.6 : 0,
          top: 0,
          right: _isDrawerOpen ? -screenWidth * 0.6 : 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _isDrawerOpen ? _toggleDrawer : null,
            child: AbsorbPointer(
              absorbing: _isDrawerOpen,
              child: widget.child,
            ),
          ),
        ),

        // Drawer menu
        SlideTransition(
          position: _drawerSlide,
          child: Container(
            width: screenWidth * 0.6,
            color: const Color(0xFF6074F9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section aligné avec les icônes
                Container(
                  padding: const EdgeInsets.only(left: 20, top: 56, right: 20),
                  child: const Text(
                    "Menu bar",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Menu items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _drawerItem(Icons.person, "Home", '/home'),
                        _drawerItem(Icons.account_balance_wallet, "Spend Line", '/spendline'),
                        _drawerItem(Icons.description, "spend Form", '/add'),
                        _drawerItem(Icons.bar_chart, "Graphique", '/stats'),
                        _drawerItem(Icons.history, "Historique", '/history'),
                        _drawerItem(Icons.person, "User Page", '/userpage'),
                        _drawerItem(Icons.notifications, "Notification", '/notification'),
                        _drawerItem(Icons.settings, "Settings", '/settings'),
                        _drawerItem(Icons.logout, "LogOut", '/logout'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Menu button
        Positioned(
          top: 40,
          left: 16,
          child: FadeTransition(
            opacity: _menuButtonFade,
            child: ScaleTransition(
              scale: _menuButtonFade,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  onPressed: _isDrawerOpen ? null : _toggleDrawer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _drawerItem(IconData icon, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton(
        onPressed: () => _navigateTo(route),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}