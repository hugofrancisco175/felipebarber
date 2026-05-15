import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';

class AgendamentosClientesPage extends StatefulWidget {
  const AgendamentosClientesPage({super.key});

  @override
  State<AgendamentosClientesPage> createState() =>
      _AgendamentosClientesPageState();
}

class _AgendamentosClientesPageState extends State<AgendamentosClientesPage> {
  final AgendamentoService _service = AgendamentoService();

  DateTime _dataSelecionada = DateTime.now();

  String _formatarDataFirebase(DateTime data) {
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  String _formatarDataTela(String data) {
    final partes = data.split('-');

    if (partes.length != 3) return data;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  String _formatarDataSelecionadaTela() {
    return _formatarDataTela(_formatarDataFirebase(_dataSelecionada));
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4A853),
              onPrimary: Colors.black,
              surface: Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Color _corStatusPagamento(String status) {
    if (status == 'Pago') return Colors.greenAccent;
    if (status.contains('Aguardando')) return Colors.orangeAccent;
    return Colors.white54;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _ordenar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    docs.sort((a, b) {
      final dadosA = a.data();
      final dadosB = b.data();

      final horarioA = dadosA['horario'] ?? '';
      final horarioB = dadosB['horario'] ?? '';

      return horarioA.toString().compareTo(horarioB.toString());
    });

    return docs;
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _agruparPorHora(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grupos =
        {};

    for (final doc in docs) {
      final horario = (doc.data()['horario'] ?? 'Sem horário').toString();

      grupos.putIfAbsent(horario, () => []);
      grupos[horario]!.add(doc);
    }

    return grupos;
  }

  Future<void> _confirmarPagamento(
    BuildContext context,
    String agendamentoId,
  ) async {
    final erro = await _service.confirmarPagamento(agendamentoId);

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
        content: Text('Pagamento confirmado com sucesso.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cancelarAgendamento(
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
    String nomeCliente,
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
          content: Text(
            'Deseja cancelar o agendamento de $nomeCliente?',
            style: const TextStyle(color: Colors.white70),
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
              onPressed: () {
                Navigator.pop(context);
                _cancelarAgendamento(context, agendamentoId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );
  }

 Widget _cardResumo({
  required String titulo,
  required String valor,
  required IconData icon,
  required Color cor,
}) {
  return Expanded(
    child: Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cor, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10.5,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _cabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: Color(0xFFD4A853),
            size: 44,
          ),
          const SizedBox(height: 10),
          const Text(
            'Agenda dos clientes',
            style: TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Visualize os clientes do dia, confirme pagamentos e acompanhe os horários da barbearia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _selecionarData,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_formatarDataSelecionadaTela()),
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

  Widget _resumoDoDia(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> agendamentos,
  ) {
    int pagos = 0;
    int pendentes = 0;

    for (final doc in agendamentos) {
      final status = (doc.data()['statusPagamento'] ?? '').toString();

      if (status == 'Pago') {
        pagos++;
      } else {
        pendentes++;
      }
    }

    return Row(
      children: [
        _cardResumo(
          titulo: 'Agendamentos',
          valor: agendamentos.length.toString(),
          icon: Icons.people_alt_outlined,
          cor: const Color(0xFFD4A853),
        ),
        const SizedBox(width: 10),
        _cardResumo(
          titulo: 'Pagos',
          valor: pagos.toString(),
          icon: Icons.check_circle_outline,
          cor: Colors.greenAccent,
        ),
        const SizedBox(width: 10),
        _cardResumo(
          titulo: 'Pendentes',
          valor: pendentes.toString(),
          icon: Icons.pending_actions,
          cor: Colors.orangeAccent,
        ),
      ],
    );
  }

  Widget _clienteCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final dados = doc.data();

    final nome = (dados['nomeCliente'] ?? 'Cliente').toString();
    final email = (dados['emailCliente'] ?? '').toString();
    final servico = (dados['servico'] ?? 'Serviço').toString();
    final formaPagamento = (dados['formaPagamento'] ?? 'Não informado').toString();
    final statusPagamento = (dados['statusPagamento'] ?? 'Pendente').toString();

    final valor = dados['valor'] is num
        ? (dados['valor'] as num).toDouble()
        : _service.valorServico(servico);

    final pago = statusPagamento == 'Pago';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pago ? Colors.greenAccent.withOpacity(0.6) : const Color(0xFF3C3C3C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFD4A853).withOpacity(0.18),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFFD4A853),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _corStatusPagamento(statusPagamento).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _corStatusPagamento(statusPagamento).withOpacity(0.7),
                  ),
                ),
                child: Text(
                  statusPagamento,
                  style: TextStyle(
                    color: _corStatusPagamento(statusPagamento),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Serviço: $servico',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor: ${_service.formatarValor(valor)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Pagamento: $formaPagamento',
            style: const TextStyle(color: Colors.white70),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'E-mail: $email',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (!pago)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarPagamento(context, doc.id),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A853),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!pago) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarCancelamento(context, doc.id, nome),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grupoHorario(
    String horario,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> clientes,
  ) {
    final vagas = AgendamentoService.capacidadePorHorario - clientes.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFFD4A853)),
              const SizedBox(width: 8),
              Text(
                horario,
                style: const TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${clientes.length}/${AgendamentoService.capacidadePorHorario} ocupadas',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vagas <= 0 ? 'Horário lotado' : '$vagas vaga(s) restante(s)',
            style: TextStyle(
              color: vagas <= 0 ? Colors.redAccent : Colors.greenAccent,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...clientes.map(_clienteCard),
        ],
      ),
    );
  }

  Widget _listaAgendamentos(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> agendamentos,
  ) {
    if (agendamentos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3C3C3C)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: Colors.white38,
              size: 44,
            ),
            SizedBox(height: 10),
            Text(
              'Nenhum cliente agendado para esta data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    final ordenados = _ordenar(agendamentos);
    final grupos = _agruparPorHora(ordenados);

    final horarios = grupos.keys.toList()..sort();

    return Column(
      children: horarios.map((horario) {
        return _grupoHorario(horario, grupos[horario]!);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFirebase = _formatarDataFirebase(_dataSelecionada);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Agenda dos clientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.buscarAgendamentosPorData(dataFirebase),
        builder: (context, snapshot) {
          final agendamentos = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _cabecalho(),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      color: Color(0xFFD4A853),
                    ),
                  )
                else ...[
                  _resumoDoDia(agendamentos),
                  const SizedBox(height: 18),
                  _listaAgendamentos(agendamentos),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}