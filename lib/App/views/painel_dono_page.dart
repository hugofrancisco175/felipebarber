import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';

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
                  const SizedBox(height: 12),
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
            _cardHorarios(),
            _cardDiasFuncionamento(),
            _cardBloqueioPeriodo(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Todos os agendamentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _listaAgendamentos(),
          ],
        ),
      ),
    );
  }
}
