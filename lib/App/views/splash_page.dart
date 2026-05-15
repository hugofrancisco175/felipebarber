import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _navegarDepoisDaSplash();
  }

  Future<void> _navegarDepoisDaSplash() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final usuario = FirebaseAuth.instance.currentUser;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (usuario != null) {
            return HomePage(usuario: usuario);
          }

          return const LoginPage();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _logo() {
    return Container(
      width: 160,
      height: 160,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A853).withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4A853), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A853).withOpacity(0.28),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.content_cut,
              size: 62,
              color: Color(0xFFD4A853),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _logo(),
              const SizedBox(height: 26),
              const Text(
                'Felipe Barber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agendamento • Estilo • Barbearia',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 58),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFD4A853),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
