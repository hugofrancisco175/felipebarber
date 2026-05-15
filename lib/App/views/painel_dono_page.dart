import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'relatorio_gerencial_page.dart';
import '../services/agendamento_service.dart';
import 'agendamentos_clientes_page.dart';

class PainelDonoPage extends StatefulWidget {
  const PainelDonoPage({super.key});

  @override
  State<PainelDonoPage> createState() => _PainelDonoPageState();
}

class _PainelDonoPageState extends State<PainelDonoPage> {
  final AgendamentoService _service = AgendamentoService();
  final TextEditingController _motivoController = TextEditingController();

  bool _carregandoConfiguracao = true;
  bool _salvandoHorarios = false;
  bool _salvandoDias = false;
  bool _salvandoBloqueio = false;

  final Set<String> _horariosSelecionados = {};
  Map<String, bool> _diasSelecionados = {};

  DateTime? _dataInicioBloqueio;
  DateTime? _dataFimBloqueio;

  Widget _botaoAbrirRelatorioGerencial(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RelatorioGerencialPage()),
          );
        },
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('Relatório gerencial'),
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

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _carregarConfiguracao() async {
    final horarios = await _service.buscarHorariosDisponiveisUmaVez();
    final dias = await _service.buscarDiasFuncionamentoUmaVez();

    if (!mounted) return;

    setState(() {
      _horariosSelecionados.clear();
      _horariosSelecionados.addAll(horarios);
      _diasSelecionados = dias;
      _carregandoConfiguracao = false;
    });
  }

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

  Color _corStatusPagamento(String status) {
    if (status == 'Pago') return Colors.greenAccent;
    if (status.contains('Aguardando')) return Colors.orangeAccent;
    return Colors.white54;
  }

  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicioBloqueio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataInicioBloqueio = data;

        if (_dataFimBloqueio != null && _dataFimBloqueio!.isBefore(data)) {
          _dataFimBloqueio = data;
        }
      });
    }
  }

  Future<void> _selecionarDataFim() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFimBloqueio ?? _dataInicioBloqueio ?? DateTime.now(),
      firstDate: _dataInicioBloqueio ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataFimBloqueio = data;
      });
    }
  }

  Future<void> _salvarHorarios() async {
    setState(() => _salvandoHorarios = true);

    await _service.salvarHorariosDisponiveis(_horariosSelecionados.toList());

    if (!mounted) return;

    setState(() => _salvandoHorarios = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Horários atualizados com sucesso.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvarDias() async {
    setState(() => _salvandoDias = true);

    await _service.salvarDiasFuncionamento(_diasSelecionados);

    if (!mounted) return;

    setState(() => _salvandoDias = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dias de funcionamento atualizados.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _adicionarBloqueio() async {
    if (_dataInicioBloqueio == null || _dataFimBloqueio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Escolha a data inicial e final.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _salvandoBloqueio = true);

    final erro = await _service.adicionarBloqueioAgenda(
      motivo: _motivoController.text,
      dataInicio: _formatarDataFirebase(_dataInicioBloqueio!),
      dataFim: _formatarDataFirebase(_dataFimBloqueio!),
    );

    if (!mounted) return;

    setState(() => _salvandoBloqueio = false);

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

    _motivoController.clear();

    setState(() {
      _dataInicioBloqueio = null;
      _dataFimBloqueio = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Período bloqueado com sucesso.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _excluirBloqueio(String bloqueioId) async {
    final erro = await _service.excluirBloqueioAgenda(bloqueioId);

    if (!mounted) return;

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
        content: Text('Bloqueio removido.'),
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

  Future<void> _marcarNotificacaoComoLida(
    BuildContext context,
    String notificacaoId,
  ) async {
    final erro = await _service.marcarNotificacaoComoLida(notificacaoId);

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
        content: Text('Notificação marcada como lida.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Widget _cardNotificacoesDono() {
    return _cardBase(
      titulo: 'Notificações do dono',
      subtitulo:
          'Aqui aparecem avisos importantes, como cancelamentos feitos pelos clientes.',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.buscarNotificacoesDono(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Color(0xFFD4A853)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text(
              'Nenhuma notificação no momento.',
              style: TextStyle(color: Colors.white54),
            );
          }

          final notificacoes = snapshot.data!.docs;

          return Column(
            children: notificacoes.map((doc) {
              final dados = doc.data();

              final titulo = dados['titulo'] ?? 'Notificação';
              final mensagem = dados['mensagem'] ?? '';
              final lida = dados['lida'] == true;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: lida
                        ? const Color(0xFF3C3C3C)
                        : const Color(0xFFD4A853),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          lida
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: lida
                              ? Colors.white38
                              : const Color(0xFFD4A853),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titulo,
                            style: TextStyle(
                              color: lida
                                  ? Colors.white70
                                  : const Color(0xFFD4A853),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mensagem,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (!lida) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _marcarNotificacaoComoLida(context, doc.id),
                          icon: const Icon(Icons.check),
                          label: const Text('Marcar como lida'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD4A853),
                            side: const BorderSide(color: Color(0xFFD4A853)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _cardHorarios() {
    return _cardBase(
      titulo: 'Horários disponíveis',
      subtitulo:
          'Ative os horários que poderão aparecer para os clientes marcarem.',
      child: Column(
        children: [
          ..._service.horariosPadrao.map((horario) {
            final ativo = _horariosSelecionados.contains(horario);

            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFFD4A853),
              title: Text(horario, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                ativo ? 'Disponível' : 'Indisponível',
                style: TextStyle(
                  color: ativo ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              value: ativo,
              onChanged: (valor) {
                setState(() {
                  if (valor) {
                    _horariosSelecionados.add(horario);
                  } else {
                    _horariosSelecionados.remove(horario);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 12),
          _botaoSalvar(
            texto: _salvandoHorarios ? 'Salvando...' : 'Salvar horários',
            carregando: _salvandoHorarios,
            onPressed: _salvarHorarios,
          ),
        ],
      ),
    );
  }

  Widget _cardDiasFuncionamento() {
    return _cardBase(
      titulo: 'Dias de funcionamento',
      subtitulo: 'Escolha em quais dias da semana a barbearia estará aberta.',
      child: Column(
        children: [
          ..._service.diasSemana.map((dia) {
            final key = dia['key']!;
            final label = dia['label']!;
            final ativo = _diasSelecionados[key] ?? false;

            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFFD4A853),
              title: Text(label, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                ativo ? 'Aberto' : 'Fechado',
                style: TextStyle(
                  color: ativo ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              value: ativo,
              onChanged: (valor) {
                setState(() {
                  _diasSelecionados[key] = valor;
                });
              },
            );
          }),
          const SizedBox(height: 12),
          _botaoSalvar(
            texto: _salvandoDias ? 'Salvando...' : 'Salvar dias',
            carregando: _salvandoDias,
            onPressed: _salvarDias,
          ),
        ],
      ),
    );
  }

  Widget _cardBloqueioPeriodo() {
    final inicioTexto = _dataInicioBloqueio == null
        ? 'Escolher início'
        : _formatarDataTela(_formatarDataFirebase(_dataInicioBloqueio!));

    final fimTexto = _dataFimBloqueio == null
        ? 'Escolher fim'
        : _formatarDataTela(_formatarDataFirebase(_dataFimBloqueio!));

    return _cardBase(
      titulo: 'Bloquear período',
      subtitulo:
          'Use para viagem, férias, reforma ou qualquer período sem atendimento.',
      child: Column(
        children: [
          TextFormField(
            controller: _motivoController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ex: Viagem',
              labelStyle: const TextStyle(color: Colors.white54),
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selecionarDataInicio,
                  icon: const Icon(Icons.date_range),
                  label: Text(inicioTexto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4A853),
                    side: const BorderSide(color: Color(0xFFD4A853)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selecionarDataFim,
                  icon: const Icon(Icons.event_available),
                  label: Text(fimTexto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4A853),
                    side: const BorderSide(color: Color(0xFFD4A853)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _botaoSalvar(
            texto: _salvandoBloqueio ? 'Bloqueando...' : 'Adicionar bloqueio',
            carregando: _salvandoBloqueio,
            onPressed: _adicionarBloqueio,
          ),
          const SizedBox(height: 20),
          _listaBloqueios(),
        ],
      ),
    );
  }

  Widget _listaBloqueios() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.buscarBloqueiosAgenda(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'Nenhum período bloqueado.',
            style: TextStyle(color: Colors.white54),
          );
        }

        final bloqueios = snapshot.data!.docs;

        return Column(
          children: bloqueios.map((doc) {
            final dados = doc.data();

            final motivo = dados['motivo'] ?? 'Agenda bloqueada';
            final inicio = dados['dataInicio'] ?? '';
            final fim = dados['dataFim'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3C3C3C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$motivo\n${_formatarDataTela(inicio)} até ${_formatarDataTela(fim)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _excluirBloqueio(doc.id),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _listaAgendamentos() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.buscarTodosAgendamentos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Nenhum agendamento encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final agendamentos = _ordenarAgendamentos(snapshot.data!.docs);

        return Column(
          children: agendamentos.map((doc) {
            final dados = doc.data();

            final nome = dados['nomeCliente'] ?? 'Cliente';
            final email = dados['emailCliente'] ?? '';
            final servico = dados['servico'] ?? 'Serviço';
            final data = dados['data'] ?? '';
            final horario = dados['horario'] ?? '';
            final formaPagamento = dados['formaPagamento'] ?? 'Não informado';
            final statusPagamento = dados['statusPagamento'] ?? 'Pendente';

            final valor = dados['valor'] is num
                ? (dados['valor'] as num).toDouble()
                : _service.valorServico(servico.toString());

            final pagamentoPago = statusPagamento == 'Pago';

            return Container(
              width: double.infinity,
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
                    '$servico - ${_formatarDataTela(data)} às $horario',
                    style: const TextStyle(
                      color: Color(0xFFD4A853),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliente: $nome',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'E-mail: $email',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valor: ${_service.formatarValor(valor)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pagamento: $formaPagamento',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: $statusPagamento',
                    style: TextStyle(
                      color: _corStatusPagamento(statusPagamento),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!pagamentoPago)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmarPagamento(context, doc.id),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Confirmar pagamento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A853),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (!pagamentoPago) const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelarAgendamento(context, doc.id),
                      icon: const Icon(Icons.delete_outline),
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
          }).toList(),
        );
      },
    );
  }

  Widget _cardBase({
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
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
            titulo,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _botaoSalvar({
    required String texto,
    required bool carregando,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: carregando ? null : onPressed,
        icon: carregando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.save),
        label: Text(texto),
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

  Widget _botaoAbrirAgendaClientes(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgendamentosClientesPage()),
          );
        },
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Agenda dos clientes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4A853),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _cabecalhoPainel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: Color(0xFFD4A853),
            size: 46,
          ),
          SizedBox(height: 10),
          Text(
            'Área administrativa',
            style: TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Gerencie agenda, pagamentos, horários, bloqueios e relatórios da barbearia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _secaoExpansivel({
    required String titulo,
    required String subtitulo,
    required IconData icon,
    required Widget child,
    bool inicialmenteAberta = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: inicialmenteAberta,
          iconColor: const Color(0xFFD4A853),
          collapsedIconColor: const Color(0xFFD4A853),
          leading: Icon(icon, color: const Color(0xFFD4A853)),
          title: Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitulo,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [child],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (!_service.usuarioEhDono(usuario)) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          title: const Text('Acesso negado'),
        ),
        body: const Center(
          child: Text(
            'Esta área é restrita ao dono da barbearia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    if (_carregandoConfiguracao) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4A853)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Painel do dono',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _cabecalhoPainel(),

            _botaoAbrirAgendaClientes(context),

            const SizedBox(height: 12),

            _botaoAbrirRelatorioGerencial(context),

            const SizedBox(height: 22),

            _secaoExpansivel(
              titulo: 'Notificações',
              subtitulo: 'Avisos de cancelamentos feitos pelos clientes.',
              icon: Icons.notifications_active_outlined,
              inicialmenteAberta: true,
              child: _cardNotificacoesDono(),
            ),

            _secaoExpansivel(
              titulo: 'Horários disponíveis',
              subtitulo: 'Ative ou desative horários da agenda.',
              icon: Icons.schedule,
              child: _cardHorarios(),
            ),

            _secaoExpansivel(
              titulo: 'Dias de funcionamento',
              subtitulo: 'Defina os dias em que a barbearia atende.',
              icon: Icons.calendar_month_outlined,
              child: _cardDiasFuncionamento(),
            ),

            _secaoExpansivel(
              titulo: 'Bloquear período',
              subtitulo: 'Use para viagem, folga, férias ou reforma.',
              icon: Icons.block,
              child: _cardBloqueioPeriodo(),
            ),
          ],
        ),
      ),
    );
  }
}
