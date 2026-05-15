import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/gemini_service.dart';
import 'agendamento_page.dart';

class ConsultorIaPage extends StatefulWidget {
  const ConsultorIaPage({super.key});

  @override
  State<ConsultorIaPage> createState() => _ConsultorIaPageState();
}

class _ConsultorIaPageState extends State<ConsultorIaPage> {
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _preferenciaController = TextEditingController();

  XFile? _imagemSelecionada;
  String? _respostaIa;
  bool _carregando = false;

  @override
  void dispose() {
    _preferenciaController.dispose();
    super.dispose();
  }

  String _mimeTypeDaImagem(XFile imagem) {
    final nome = imagem.name.toLowerCase();

    if (nome.endsWith('.png')) {
      return 'image/png';
    }

    if (nome.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  Future<void> _selecionarImagem() async {
    final imagem = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 900,
    );

    if (imagem == null) return;

    setState(() {
      _imagemSelecionada = imagem;
      _respostaIa = null;
    });
  }

  Future<void> _gerarSugestao() async {
    if (_imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione uma foto primeiro.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _carregando = true;
      _respostaIa = null;
    });

    final Uint8List bytes = await _imagemSelecionada!.readAsBytes();

    final resposta = await _geminiService.sugerirCortes(
      imagemBytes: bytes,
      mimeType: _mimeTypeDaImagem(_imagemSelecionada!),
      preferencia: _preferenciaController.text,
    );

    if (!mounted) return;

    setState(() {
      _respostaIa = resposta;
      _carregando = false;
    });
  }

  Widget _cardImagem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Column(
        children: [
          if (_imagemSelecionada == null)
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3C3C3C)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: Color(0xFFD4A853),
                    size: 54,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Selecione uma foto para análise',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_imagemSelecionada!.path),
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _carregando ? null : _selecionarImagem,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _imagemSelecionada == null
                    ? 'Escolher foto'
                    : 'Trocar foto',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4A853),
                side: const BorderSide(color: Color(0xFFD4A853)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoPreferencia() {
    return TextFormField(
      controller: _preferenciaController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Preferência opcional',
        hintText: 'Ex: quero algo moderno, baixo, social, degradê...',
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        prefixIcon: const Icon(
          Icons.tips_and_updates_outlined,
          color: Colors.white38,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD4A853),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _botaoGerar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _carregando ? null : _gerarSugestao,
        icon: _carregando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _carregando ? 'Analisando foto...' : 'Gerar sugestão com IA',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4A853),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _cardResposta() {
    if (_respostaIa == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4A853)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resultado da IA',
            style: TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _respostaIa!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AgendamentoPage(servico: 'Corte'),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Agendar corte'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4A853),
                side: const BorderSide(color: Color(0xFFD4A853)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
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
          'Consultor de Corte com IA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 105,
              height: 105,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A853).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4A853),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFD4A853),
                      size: 52,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Envie uma foto e receba sugestões de cortes que podem combinar com você.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            _cardImagem(),
            const SizedBox(height: 18),
            _campoPreferencia(),
            const SizedBox(height: 18),
            _botaoGerar(),
            const SizedBox(height: 22),
            _cardResposta(),
          ],
        ),
      ),
    );
  }
}