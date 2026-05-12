import 'package:flutter/material.dart';

import '../services/status_service.dart';

class VerStatusPage extends StatelessWidget {
  final String statusId;
  final String titulo;
  final String legenda;
  final String imagemAsset;
  final bool podeExcluir;

  VerStatusPage({
    super.key,
    required this.statusId,
    required this.titulo,
    required this.legenda,
    required this.imagemAsset,
    required this.podeExcluir,
  });

  final StatusService _service = StatusService();

  Future<void> _excluir(BuildContext context) async {
    final erro = await _service.excluirStatus(statusId);

    if (!context.mounted) return;

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status excluído.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Excluir status',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja excluir este status?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _excluir(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Status'),
        centerTitle: true,
        actions: [
          if (podeExcluir)
            IconButton(
              tooltip: 'Excluir status',
              onPressed: () => _confirmarExclusao(context),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                imagemAsset,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 280,
                    width: double.infinity,
                    color: const Color(0xFF2C2C2C),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 70,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                legenda,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
