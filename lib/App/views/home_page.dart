import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final UsuarioModel usuario;

  const HomePage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Barbearia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFD4A853)),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone principal
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A853).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A853),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 56,
                color: Color(0xFFD4A853),
              ),
            ),
            const SizedBox(height: 28),

            // Texto de boas-vindas
            const Text(
              'Bem-vindo à Home!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Olá, ${usuario.nome} 👋',
              style: const TextStyle(
                color: Color(0xFFD4A853),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 48),

            // Cards de serviços (diferencial visual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _servicoCard(Icons.content_cut, 'Corte'),
                  _servicoCard(Icons.face_retouching_natural, 'Barba'),
                  _servicoCard(Icons.star_outline, 'Combo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicoCard(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3C3C3C)),
          ),
          child: Icon(icon, color: const Color(0xFFD4A853), size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
