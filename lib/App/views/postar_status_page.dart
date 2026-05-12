import 'package:flutter/material.dart';

import '../services/status_service.dart';

class PostarStatusPage extends StatefulWidget {
  const PostarStatusPage({super.key});

  @override
  State<PostarStatusPage> createState() => _PostarStatusPageState();
}

class _PostarStatusPageState extends State<PostarStatusPage> {
  final StatusService _service = StatusService();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _legendaController = TextEditingController();

  bool _carregando = false;
  String _imagemSelecionada = StatusService.imagensDisponiveis.first['asset']!;

  @override
  void dispose() {
    _tituloController.dispose();
    _legendaController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    setState(() => _carregando = true);

    final erro = await _service.postarStatus(
      titulo: _tituloController.text,
      legenda: _legendaController.text,
      imagemAsset: _imagemSelecionada,
    );

    if (!mounted) return;

    setState(() => _carregando = false);

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
        content: Text('Status publicado com sucesso.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  Widget _imagemOpcao(Map<String, String> imagem) {
    final nome = imagem['nome']!;
    final asset = imagem['asset']!;
    final selecionada = _imagemSelecionada == asset;

    return GestureDetector(
      onTap: () {
        setState(() => _imagemSelecionada = asset);
      },
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionada
                      ? const Color(0xFFD4A853)
                      : const Color(0xFF3C3C3C),
                  width: selecionada ? 3 : 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFF2C2C2C),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selecionada ? const Color(0xFFD4A853) : Colors.white70,
                fontSize: 12,
                fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4A853), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Postar status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha uma imagem',
              style: TextStyle(
                color: Color(0xFFD4A853),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 112,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: StatusService.imagensDisponiveis
                    .map(_imagemOpcao)
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _tituloController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Título', Icons.title),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _legendaController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: _inputDecoration('Legenda', Icons.description),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _carregando ? null : _publicar,
                icon: _carregando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_carregando ? 'Publicando...' : 'Publicar status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A853),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}