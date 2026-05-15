import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/agendamento_service.dart';
import '../services/gemini_service.dart';

class RelatorioGerencialPage extends StatefulWidget {
  const RelatorioGerencialPage({super.key});

  @override
  State<RelatorioGerencialPage> createState() => _RelatorioGerencialPageState();
}

class _RelatorioGerencialPageState extends State<RelatorioGerencialPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AgendamentoService _agendamentoService = AgendamentoService();
  final GeminiService _geminiService = GeminiService();

  late Future<Map<String, dynamic>> _futureResumo;

  bool _gerandoIa = false;
  String? _analiseIa;

  @override
  void initState() {
    super.initState();
    _futureResumo = _carregarResumoGerencial();
  }

  String _formatarDinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  bool _pagamentoConfirmado(String status) {
    return status.toLowerCase() == 'pago';
  }

  bool _pagamentoAguardandoPix(String forma, String status) {
    return forma.toLowerCase() == 'pix' &&
        status.toLowerCase().contains('aguardando');
  }

  bool _pagamentoLocalPendente(String forma, String status) {
    return forma.toLowerCase().contains('local') &&
        !_pagamentoConfirmado(status);
  }

  Future<Map<String, dynamic>> _carregarResumoGerencial() async {
    final agendamentosSnapshot =
        await _firestore.collection('agendamentos').get();

    final notificacoesSnapshot =
        await _firestore.collection('notificacoes_dono').get();

    double totalPrevisto = 0;
    double totalRecebido = 0;
    double totalPendente = 0;
    double totalPixAguardando = 0;
    double totalLocalPendente = 0;

    int qtdAgendamentos = 0;
    int qtdPagos = 0;
    int qtdPendentes = 0;
    int qtdPixAguardando = 0;
    int qtdLocalPendente = 0;
    int qtdCancelamentos = 0;

    final Map<String, int> qtdPorServico = {};
    final Map<String, double> valorPorServico = {};
    final Map<String, int> qtdPorHorario = {};
    final Map<String, int> qtdPorPagamento = {};

    for (final doc in agendamentosSnapshot.docs) {
      final dados = doc.data();

      final servico = (dados['servico'] ?? 'Serviço').toString();
      final horario = (dados['horario'] ?? 'Sem horário').toString();
      final formaPagamento =
          (dados['formaPagamento'] ?? 'Não informado').toString();
      final statusPagamento =
          (dados['statusPagamento'] ?? 'Pendente').toString();

      final valor = dados['valor'] is num
          ? (dados['valor'] as num).toDouble()
          : _agendamentoService.valorServico(servico);

      qtdAgendamentos++;
      totalPrevisto += valor;

      qtdPorServico[servico] = (qtdPorServico[servico] ?? 0) + 1;
      valorPorServico[servico] = (valorPorServico[servico] ?? 0) + valor;
      qtdPorHorario[horario] = (qtdPorHorario[horario] ?? 0) + 1;
      qtdPorPagamento[formaPagamento] =
          (qtdPorPagamento[formaPagamento] ?? 0) + 1;

      if (_pagamentoConfirmado(statusPagamento)) {
        qtdPagos++;
        totalRecebido += valor;
      } else {
        qtdPendentes++;
        totalPendente += valor;
      }

      if (_pagamentoAguardandoPix(formaPagamento, statusPagamento)) {
        qtdPixAguardando++;
        totalPixAguardando += valor;
      }

      if (_pagamentoLocalPendente(formaPagamento, statusPagamento)) {
        qtdLocalPendente++;
        totalLocalPendente += valor;
      }
    }

    for (final doc in notificacoesSnapshot.docs) {
      final dados = doc.data();

      if ((dados['tipo'] ?? '').toString() == 'cancelamento') {
        qtdCancelamentos++;
      }
    }

    final ticketMedio =
        qtdAgendamentos == 0 ? 0.0 : totalPrevisto / qtdAgendamentos;

    return {
      'totalPrevisto': totalPrevisto,
      'totalRecebido': totalRecebido,
      'totalPendente': totalPendente,
      'totalPixAguardando': totalPixAguardando,
      'totalLocalPendente': totalLocalPendente,
      'qtdAgendamentos': qtdAgendamentos,
      'qtdPagos': qtdPagos,
      'qtdPendentes': qtdPendentes,
      'qtdPixAguardando': qtdPixAguardando,
      'qtdLocalPendente': qtdLocalPendente,
      'qtdCancelamentos': qtdCancelamentos,
      'ticketMedio': ticketMedio,
      'qtdPorServico': qtdPorServico,
      'valorPorServico': valorPorServico,
      'qtdPorHorario': qtdPorHorario,
      'qtdPorPagamento': qtdPorPagamento,
    };
  }

  String _montarResumoParaIa(Map<String, dynamic> resumo) {
    final totalPrevisto = resumo['totalPrevisto'] as double;
    final totalRecebido = resumo['totalRecebido'] as double;
    final totalPendente = resumo['totalPendente'] as double;
    final totalPixAguardando = resumo['totalPixAguardando'] as double;
    final totalLocalPendente = resumo['totalLocalPendente'] as double;

    final qtdAgendamentos = resumo['qtdAgendamentos'] as int;
    final qtdPagos = resumo['qtdPagos'] as int;
    final qtdPendentes = resumo['qtdPendentes'] as int;
    final qtdPixAguardando = resumo['qtdPixAguardando'] as int;
    final qtdLocalPendente = resumo['qtdLocalPendente'] as int;
    final qtdCancelamentos = resumo['qtdCancelamentos'] as int;
    final ticketMedio = resumo['ticketMedio'] as double;

    final qtdPorServico = resumo['qtdPorServico'] as Map<String, int>;
    final valorPorServico = resumo['valorPorServico'] as Map<String, double>;
    final qtdPorHorario = resumo['qtdPorHorario'] as Map<String, int>;
    final qtdPorPagamento = resumo['qtdPorPagamento'] as Map<String, int>;

    return '''
Faturamento previsto: ${_formatarDinheiro(totalPrevisto)}
Faturamento recebido: ${_formatarDinheiro(totalRecebido)}
Faturamento pendente: ${_formatarDinheiro(totalPendente)}
Pix aguardando confirmação: ${_formatarDinheiro(totalPixAguardando)}
Pagamento no local pendente: ${_formatarDinheiro(totalLocalPendente)}

Quantidade de agendamentos ativos: $qtdAgendamentos
Pagamentos confirmados: $qtdPagos
Pagamentos pendentes: $qtdPendentes
Pix aguardando confirmação: $qtdPixAguardando
Pagamentos no local pendentes: $qtdLocalPendente
Cancelamentos registrados: $qtdCancelamentos
Ticket médio previsto: ${_formatarDinheiro(ticketMedio)}

Quantidade por serviço:
${qtdPorServico.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Faturamento por serviço:
${valorPorServico.entries.map((e) => '- ${e.key}: ${_formatarDinheiro(e.value)}').join('\n')}

Agendamentos por horário:
${qtdPorHorario.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Formas de pagamento:
${qtdPorPagamento.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
''';
  }

  Future<void> _gerarAnaliseIa(Map<String, dynamic> resumo) async {
    setState(() {
      _gerandoIa = true;
      _analiseIa = null;
    });

    final resumoTexto = _montarResumoParaIa(resumo);

    final resposta = await _geminiService.gerarRelatorioGerencial(
      resumoGerencial: resumoTexto,
    );

    if (!mounted) return;

    setState(() {
      _analiseIa = resposta;
      _gerandoIa = false;
    });
  }

  void _atualizar() {
    setState(() {
      _analiseIa = null;
      _futureResumo = _carregarResumoGerencial();
    });
  }

  Widget _cardValor({
    required String titulo,
    required String valor,
    required IconData icon,
    Color cor = const Color(0xFFD4A853),
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    color: cor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaIndicador(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBase({
    required String titulo,
    required Widget child,
  }) {
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
            titulo,
            style: const TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _listaValoresServico(Map<String, double> mapa) {
    final itens = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (itens.isEmpty) {
      return const Text(
        'Nenhum dado disponível.',
        style: TextStyle(color: Colors.white54),
      );
    }

    return Column(
      children: itens.map((item) {
        return _linhaIndicador(item.key, _formatarDinheiro(item.value));
      }).toList(),
    );
  }

  Widget _listaQuantidades(Map<String, int> mapa) {
    final itens = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (itens.isEmpty) {
      return const Text(
        'Nenhum dado disponível.',
        style: TextStyle(color: Colors.white54),
      );
    }

    return Column(
      children: itens.map((item) {
        return _linhaIndicador(item.key, item.value.toString());
      }).toList(),
    );
  }

  Widget _cardResumoNumerico(Map<String, dynamic> resumo) {
    final totalPrevisto = resumo['totalPrevisto'] as double;
    final totalRecebido = resumo['totalRecebido'] as double;
    final totalPendente = resumo['totalPendente'] as double;
    final totalPixAguardando = resumo['totalPixAguardando'] as double;
    final totalLocalPendente = resumo['totalLocalPendente'] as double;
    final ticketMedio = resumo['ticketMedio'] as double;

    final qtdAgendamentos = resumo['qtdAgendamentos'] as int;
    final qtdPagos = resumo['qtdPagos'] as int;
    final qtdPendentes = resumo['qtdPendentes'] as int;
    final qtdCancelamentos = resumo['qtdCancelamentos'] as int;

    return Column(
      children: [
        _cardValor(
          titulo: 'Faturamento previsto',
          valor: _formatarDinheiro(totalPrevisto),
          icon: Icons.trending_up,
        ),
        _cardValor(
          titulo: 'Faturamento recebido',
          valor: _formatarDinheiro(totalRecebido),
          icon: Icons.check_circle_outline,
          cor: Colors.greenAccent,
        ),
        _cardValor(
          titulo: 'Faturamento pendente',
          valor: _formatarDinheiro(totalPendente),
          icon: Icons.pending_actions,
          cor: Colors.orangeAccent,
        ),
        _cardValor(
          titulo: 'Pix aguardando confirmação',
          valor: _formatarDinheiro(totalPixAguardando),
          icon: Icons.pix,
          cor: Colors.lightBlueAccent,
        ),
        _cardValor(
          titulo: 'Pagamento no local pendente',
          valor: _formatarDinheiro(totalLocalPendente),
          icon: Icons.storefront,
          cor: Colors.white70,
        ),
        _cardBase(
          titulo: 'Indicadores gerais',
          child: Column(
            children: [
              _linhaIndicador(
                'Agendamentos ativos',
                qtdAgendamentos.toString(),
              ),
              _linhaIndicador(
                'Pagamentos confirmados',
                qtdPagos.toString(),
              ),
              _linhaIndicador(
                'Pagamentos pendentes',
                qtdPendentes.toString(),
              ),
              _linhaIndicador(
                'Cancelamentos registrados',
                qtdCancelamentos.toString(),
              ),
              _linhaIndicador(
                'Ticket médio previsto',
                _formatarDinheiro(ticketMedio),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardAnaliseIa(Map<String, dynamic> resumo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4A853)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análise com IA',
            style: TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _gerandoIa ? null : () => _gerarAnaliseIa(resumo),
              icon: _gerandoIa
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
                _gerandoIa
                    ? 'Gerando análise...'
                    : 'Gerar relatório inteligente',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_analiseIa != null) ...[
            const SizedBox(height: 16),
            Text(
              _analiseIa!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _conteudo(Map<String, dynamic> resumo) {
    final valorPorServico = resumo['valorPorServico'] as Map<String, double>;
    final qtdPorServico = resumo['qtdPorServico'] as Map<String, int>;
    final qtdPorHorario = resumo['qtdPorHorario'] as Map<String, int>;
    final qtdPorPagamento = resumo['qtdPorPagamento'] as Map<String, int>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _cardResumoNumerico(resumo),
          _cardBase(
            titulo: 'Faturamento por serviço',
            child: _listaValoresServico(valorPorServico),
          ),
          _cardBase(
            titulo: 'Quantidade por serviço',
            child: _listaQuantidades(qtdPorServico),
          ),
          _cardBase(
            titulo: 'Horários mais movimentados',
            child: _listaQuantidades(qtdPorHorario),
          ),
          _cardBase(
            titulo: 'Formas de pagamento',
            child: _listaQuantidades(qtdPorPagamento),
          ),
          _cardAnaliseIa(resumo),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (!_agendamentoService.usuarioEhDono(usuario)) {
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
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Relatório Gerencial',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizar,
            icon: const Icon(Icons.refresh, color: Color(0xFFD4A853)),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureResumo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar relatório gerencial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          final resumo = snapshot.data;

          if (resumo == null) {
            return const Center(
              child: Text(
                'Nenhum dado encontrado.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return _conteudo(resumo);
        },
      ),
    );
  }
}