import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';
import '../services/notificacao_service.dart';

class AgendamentoPage extends StatefulWidget {
  final String servico;

  const AgendamentoPage({
    super.key,
    required this.servico,
  });

  @override
  State<AgendamentoPage> createState() => _AgendamentoPageState();
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  final AgendamentoService _service = AgendamentoService();

  DateTime _dataSelecionada = DateTime.now();
  bool _carregando = false;
  String _formaPagamento = 'Pagar no local';

  String _formatarData(DateTime data) {
    final ano = data.year.toString();
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  String _formatarDataTela(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> _selecionarData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    if (dataEscolhida != null) {
      setState(() {
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  Future<void> _confirmarAgendamento(String horario) async {
    setState(() => _carregando = true);

    final data = _formatarData(_dataSelecionada);

    final erro = await _service.agendarHorario(
      servico: widget.servico,
      data: data,
      horario: horario,
      formaPagamento: _formaPagamento,
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

    final agendamentoId = _service.gerarIdAgendamento(data, horario);

    await NotificacaoService.agendarNotificacoesAgendamento(
      agendamentoId: agendamentoId,
      servico: widget.servico,
      data: data,
      horario: horario,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ ${widget.servico} agendado para ${_formatarDataTela(_dataSelecionada)} às $horario',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarConfirmacao(String horario) {
    final valor = _service.valorServico(widget.servico);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Confirmar agendamento',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Serviço: ${widget.servico}\n'
            'Valor: ${_service.formatarValor(valor)}\n'
            'Data: ${_formatarDataTela(_dataSelecionada)} às $horario\n'
            'Pagamento: $_formaPagamento'
            '${_formaPagamento == 'Pix' ? '\n\nChave Pix: ${AgendamentoService.chavePix}\nApós o pagamento, o dono confirmará no painel.' : ''}',
            style: const TextStyle(color: Colors.white70),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                _confirmarAgendamento(horario);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Widget _mensagemBloqueio(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cardPagamento() {
    final valor = _service.valorServico(widget.servico);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pagamento',
            style: TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Valor: ${_service.formatarValor(valor)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFD4A853),
            title: const Text(
              'Pagar no local',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Pagamento feito na barbearia',
              style: TextStyle(color: Colors.white54),
            ),
            value: 'Pagar no local',
            groupValue: _formaPagamento,
            onChanged: (value) {
              if (value != null) {
                setState(() => _formaPagamento = value);
              }
            },
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFD4A853),
            title: const Text(
              'Pix',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'O dono confirmará o pagamento no painel',
              style: TextStyle(color: Colors.white54),
            ),
            value: 'Pix',
            groupValue: _formaPagamento,
            onChanged: (value) {
              if (value != null) {
                setState(() => _formaPagamento = value);
              }
            },
          ),
          if (_formaPagamento == 'Pix') ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4A853)),
              ),
              child: const Text(
                'Chave Pix: ${AgendamentoService.chavePix}',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataFirebase = _formatarData(_dataSelecionada);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: Text(
          'Agendar ${widget.servico}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _service.buscarConfiguracaoAgenda(),
        builder: (context, configSnapshot) {
          if (configSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4A853),
              ),
            );
          }

          final config = configSnapshot.data ?? {};
          final List<String> horariosDisponiveis =
              List<String>.from(config['horariosDisponiveis'] ?? []);

          final Map<String, bool> diasFuncionamento =
              Map<String, bool>.from(config['diasFuncionamento'] ?? {});

          final chaveDia = _service.chaveDiaSemanaPorData(dataFirebase);
          final nomeDia = _service.nomeDiaSemanaPorChave(chaveDia);
          final diaAberto = diasFuncionamento[chaveDia] == true;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.buscarBloqueiosAgenda(),
            builder: (context, bloqueiosSnapshot) {
              final bloqueios = bloqueiosSnapshot.data?.docs ?? [];

              final dataBloqueada = _service.dataEstaBloqueadaPelosDados(
                dataFirebase,
                bloqueios,
              );

              final motivoBloqueio = _service.motivoBloqueioParaData(
                dataFirebase,
                bloqueios,
              );

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.buscarAgendamentosPorData(dataFirebase),
                builder: (context, snapshot) {
                  final Map<String, int> quantidadePorHorario = {};

                  if (snapshot.hasData) {
                    for (final doc in snapshot.data!.docs) {
                      final dados = doc.data();
                      final horario = dados['horario'] ?? '';
                      quantidadePorHorario[horario] =
                          (quantidadePorHorario[horario] ?? 0) + 1;
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 105,
                          height: 105,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A853).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD4A853),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            size: 54,
                            color: Color(0xFFD4A853),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.servico,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escolha o dia, o pagamento e o horário desejado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _selecionarData,
                            icon: const Icon(
                              Icons.event,
                              color: Color(0xFFD4A853),
                            ),
                            label: Text(
                              '${_formatarDataTela(_dataSelecionada)} - $nomeDia',
                              style: const TextStyle(
                                color: Color(0xFFD4A853),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFD4A853),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _cardPagamento(),
                        const SizedBox(height: 28),
                        if (!diaAberto)
                          _mensagemBloqueio(
                            'A barbearia não atende em $nomeDia.',
                          )
                        else if (dataBloqueada)
                          _mensagemBloqueio(
                            'A barbearia não atenderá nesta data.\nMotivo: ${motivoBloqueio ?? 'Agenda bloqueada'}',
                          )
                        else ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Horários disponíveis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (horariosDisponiveis.isEmpty)
                            const Text(
                              'Nenhum horário disponível no momento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: horariosDisponiveis.map((horario) {
                                final quantidade =
                                    quantidadePorHorario[horario] ?? 0;

                                final vagasRestantes =
                                    AgendamentoService.capacidadePorHorario -
                                        quantidade;

                                final lotado = vagasRestantes <= 0;

                                return SizedBox(
                                  width: 112,
                                  height: 62,
                                  child: ElevatedButton(
                                    onPressed: lotado || _carregando
                                        ? null
                                        : () => _mostrarConfirmacao(horario),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: lotado
                                          ? const Color(0xFF3A3A3A)
                                          : const Color(0xFFD4A853),
                                      disabledBackgroundColor:
                                          const Color(0xFF3A3A3A),
                                      foregroundColor: lotado
                                          ? Colors.white38
                                          : Colors.black,
                                      disabledForegroundColor: Colors.white38,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      lotado
                                          ? '$horario\nLotado'
                                          : '$horario\n$vagasRestantes vagas',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3C3C3C),
                            ),
                          ),
                          child: const Text(
                            'Cada horário aceita até 3 clientes, pois a barbearia possui 3 barbeiros disponíveis.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}