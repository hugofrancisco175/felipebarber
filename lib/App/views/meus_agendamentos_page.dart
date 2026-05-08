import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';

class MeusAgendamentosPage extends StatelessWidget {
  MeusAgendamentosPage({super.key});

  final AgendamentoService _service = AgendamentoService();

  String _formatarData(String data) {
    final partes = data.split('-');

    if (partes.length != 3) return data;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _ordenarAgendamentos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    docs.sort((a, b) {
      final dadosA = a.data();
      final dadosB = b.data();

      final dataA = '${dadosA['data'] ?? ''} ${dadosA['horario'] ?? ''}';
      final dataB = '${dadosB['data'] ?? ''} ${dadosB['horario'] ?? ''}';

      return dataA.compareTo(dataB);
    });

    return docs;
  }

  Future<void> _cancelar(
    BuildContext context,
    String agendamentoId,
  ) async {
    final erro = await _service.cancelarAgendamento(agendamentoId);

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
        content: Text('Agendamento cancelado.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmarCancelamento(
    BuildContext context,
    String agendamentoId,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Cancelar agendamento',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tem certeza que deseja cancelar este agendamento?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Não',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                _cancelar(context, agendamentoId);
              },
              child: const Text('Sim, cancelar'),
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
        title: const Text(
          'Meus agendamentos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.buscarMeusAgendamentos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4A853),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Você ainda não possui agendamentos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

          final agendamentos = _ordenarAgendamentos(snapshot.data!.docs);

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: agendamentos.length,
            itemBuilder: (context, index) {
              final doc = agendamentos[index];
              final dados = doc.data();

              final servico = dados['servico'] ?? 'Serviço';
              final data = dados['data'] ?? '';
              final horario = dados['horario'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3C3C3C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servico,
                      style: const TextStyle(
                        color: Color(0xFFD4A853),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatarData(data)} às $horario',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmarCancelamento(context, doc.id),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancelar agendamento'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}