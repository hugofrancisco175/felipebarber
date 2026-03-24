import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela Inicial')),
      body: const Center(
        child: Text('Bem-vindo!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
