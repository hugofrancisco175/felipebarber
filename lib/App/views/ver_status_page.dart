import 'package:flutter/material.dart';

import '../services/status_service.dart';

class VerStatusPage extends StatefulWidget {
  final List<Map<String, String>> statusList;
  final int initialIndex;
  final bool podeExcluir;

  const VerStatusPage({
    super.key,
    required this.statusList,
    required this.initialIndex,
    required this.podeExcluir,
  });

  @override
  State<VerStatusPage> createState() => _VerStatusPageState();
}

class _VerStatusPageState extends State<VerStatusPage> {
  final StatusService _service = StatusService();

  late PageController _pageController;
  late int _indiceAtual;

  @override
  void initState() {
    super.initState();

    _indiceAtual = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, String> get _statusAtual {
    return widget.statusList[_indiceAtual];
  }

  Future<void> _excluir(BuildContext context) async {
    final statusId = _statusAtual['statusId'] ?? '';

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

  void _proximoStatus() {
    if (_indiceAtual < widget.statusList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _statusAnterior() {
    if (_indiceAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _toqueNaTela(TapUpDetails details, BuildContext context) {
    final larguraTela = MediaQuery.of(context).size.width;
    final toqueX = details.localPosition.dx;

    if (toqueX > larguraTela / 2) {
      _proximoStatus();
    } else {
      _statusAnterior();
    }
  }

  Widget _barrasDeStatus() {
    return Row(
      children: List.generate(widget.statusList.length, (index) {
        final ativo = index <= _indiceAtual;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: ativo
                  ? const Color(0xFFD4A853)
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  Widget _imagemStatus(Map<String, String> item) {
    final imagemAsset = item['imagemAsset'] ?? 'assets/logo.png';

    return Image.asset(
      imagemAsset,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2C2C2C),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white54,
            size: 80,
          ),
        );
      },
    );
  }

  Widget _legendaStatus() {
    final titulo = _statusAtual['titulo'] ?? 'Status';
    final legenda = _statusAtual['legenda'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 90, 22, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.85),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFFD4A853),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (legenda.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                legenda,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topo(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Column(
          children: [
            _barrasDeStatus(),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4A853),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _statusAtual['imagemAsset'] ?? 'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.storefront,
                          color: Color(0xFFD4A853),
                          size: 22,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusAtual['titulo'] ?? 'Status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (widget.podeExcluir)
                  IconButton(
                    tooltip: 'Excluir status',
                    onPressed: () => _confirmarExclusao(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statusList.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          title: const Text('Status'),
        ),
        body: const Center(
          child: Text(
            'Nenhum status disponível.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _toqueNaTela(details, context),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.statusList.length,
              onPageChanged: (index) {
                setState(() {
                  _indiceAtual = index;
                });
              },
              itemBuilder: (context, index) {
                final item = widget.statusList[index];

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _imagemStatus(item),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _legendaStatus(),
                    ),
                  ],
                );
              },
            ),
          ),
          _topo(context),
        ],
      ),
    );
  }
}