import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
void initState() {
  super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1), // Fade rapide
  );

  _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

  // Attente AVANT l'animation
  Future.delayed(const Duration(seconds: 2), () async {
    await _controller.forward(); // fade de 1s
    Navigator.of(context).pushReplacementNamed('/login');
  });
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        color: const Color(0xFF6074F9), // fond bleu
        alignment: Alignment.center,
        child: const Text(
          'Phone spend',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
