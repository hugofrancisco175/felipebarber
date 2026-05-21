import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgendamentoService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  static const String emailDono = 'felipebarber@gmail.com';
  static const int capacidadePorHorario = 3;
  static const String chavePix = 'felipebarber@gmail.com';

  final List<String> horariosPadrao = const [
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  final List<Map<String, String>> diasSemana = const [
    {'key': 'segunda', 'label': 'Segunda-feira'},
    {'key': 'terca', 'label': 'Terça-feira'},
    {'key': 'quarta', 'label': 'Quarta-feira'},
    {'key': 'quinta', 'label': 'Quinta-feira'},
    {'key': 'sexta', 'label': 'Sexta-feira'},
    {'key': 'sabado', 'label': 'Sábado'},
    {'key': 'domingo', 'label': 'Domingo'},
  ];

  DocumentReference<Map<String, dynamic>> get _configAgendaRef {
    return _firestore.collection('configuracoes').doc('agenda');
  }

  bool usuarioEhDono(User? usuario) {
    return usuario?.email?.toLowerCase() == emailDono.toLowerCase();
  }

  Map<String, bool> get diasPadrao {
    return {
      'segunda': true,
      'terca': true,
      'quarta': true,
      'quinta': true,
      'sexta': true,
      'sabado': true,
      'domingo': false,
    };
  }

  double valorServico(String servico) {
    final s = servico.toLowerCase();

    if (s.contains('barba')) return 20.0;
    if (s.contains('combo')) return 60.0;
    return 40.0;
  }

  String formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String gerarIdHorario(String data, String horario) {
    final horarioFormatado = horario.replaceAll(':', '-');
    return '${data}_$horarioFormatado';
  }

  String gerarIdAgendamento(String data, String horario) {
    final usuario = _auth.currentUser;
    final userId = usuario?.uid ?? 'sem_usuario';
    final horarioFormatado = horario.replaceAll(':', '-');

    return '${data}_${horarioFormatado}_$userId';
  }

  List<String> extrairHorarios(Map<String, dynamic>? dados) {
    if (dados == null) return List<String>.from(horariosPadrao);

    final lista = dados['horariosDisponiveis'];

    if (lista is List) {
      final horarios = lista.map((e) => e.toString()).toList();
      horarios.sort();
      return horarios;
    }

    return List<String>.from(horariosPadrao);
  }

  Map<String, bool> extrairDiasFuncionamento(Map<String, dynamic>? dados) {
    final dias = diasPadrao;

    if (dados == null) return dias;

    final mapa = dados['diasFuncionamento'];

    if (mapa is Map) {
      for (final dia in dias.keys) {
        if (mapa[dia] is bool) {
          dias[dia] = mapa[dia];
        }
      }
    }

    return dias;
  }

  Stream<Map<String, dynamic>> buscarConfiguracaoAgenda() {
    return _configAgendaRef.snapshots().map((snapshot) {
      final dados = snapshot.data();

      return {
        'horariosDisponiveis': extrairHorarios(dados),
        'diasFuncionamento': extrairDiasFuncionamento(dados),
      };
    });
  }

  Future<List<String>> buscarHorariosDisponiveisUmaVez() async {
    final snapshot = await _configAgendaRef.get();
    return extrairHorarios(snapshot.data());
  }

  Future<Map<String, bool>> buscarDiasFuncionamentoUmaVez() async {
    final snapshot = await _configAgendaRef.get();
    return extrairDiasFuncionamento(snapshot.data());
  }

  Future<void> salvarHorariosDisponiveis(List<String> horarios) async {
    horarios.sort();

    await _configAgendaRef.set({
      'horariosDisponiveis': horarios,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> salvarDiasFuncionamento(Map<String, bool> dias) async {
    await _configAgendaRef.set({
      'diasFuncionamento': dias,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String chaveDiaSemanaPorData(String data) {
    final dataConvertida = DateTime.parse(data);

    switch (dataConvertida.weekday) {
      case DateTime.monday:
        return 'segunda';
      case DateTime.tuesday:
        return 'terca';
      case DateTime.wednesday:
        return 'quarta';
      case DateTime.thursday:
        return 'quinta';
      case DateTime.friday:
        return 'sexta';
      case DateTime.saturday:
        return 'sabado';
      case DateTime.sunday:
        return 'domingo';
      default:
        return 'segunda';
    }
  }

  String nomeDiaSemanaPorChave(String chave) {
    final encontrado = diasSemana.firstWhere(
      (dia) => dia['key'] == chave,
      orElse: () => {'key': chave, 'label': chave},
    );

    return encontrado['label'] ?? chave;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buscarAgendamentosPorData(
    String data,
  ) {
    return _firestore
        .collection('agendamentos')
        .where('data', isEqualTo: data)
        .where('statusAgendamento', whereIn: ['ativo', 'concluido'])
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buscarMeusAgendamentos() {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('agendamentos')
        .where('usuarioId', isEqualTo: usuario.uid)
        .where('statusAgendamento', isEqualTo: 'ativo')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buscarTodosAgendamentos() {
    return _firestore.collection('agendamentos').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buscarBloqueiosAgenda() {
    return _firestore.collection('bloqueios_agenda').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buscarNotificacoesDono() {
    return _firestore
        .collection('notificacoes_dono')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  bool dataEstaBloqueadaPelosDados(
    String data,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bloqueios,
  ) {
    for (final doc in bloqueios) {
      final dados = doc.data();

      final inicio = dados['dataInicio'] ?? '';
      final fim = dados['dataFim'] ?? '';

      if (inicio.toString().compareTo(data) <= 0 &&
          fim.toString().compareTo(data) >= 0) {
        return true;
      }
    }

    return false;
  }

  String? motivoBloqueioParaData(
    String data,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bloqueios,
  ) {
    for (final doc in bloqueios) {
      final dados = doc.data();

      final inicio = dados['dataInicio'] ?? '';
      final fim = dados['dataFim'] ?? '';

      if (inicio.toString().compareTo(data) <= 0 &&
          fim.toString().compareTo(data) >= 0) {
        return dados['motivo'] ?? 'Agenda bloqueada';
      }
    }

    return null;
  }

  Future<bool> existeBloqueioParaData(String data) async {
    final snapshot = await _firestore.collection('bloqueios_agenda').get();

    return dataEstaBloqueadaPelosDados(data, snapshot.docs);
  }

  Future<String?> adicionarBloqueioAgenda({
    required String motivo,
    required String dataInicio,
    required String dataFim,
  }) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode bloquear a agenda.';
    }

    if (dataInicio.compareTo(dataFim) > 0) {
      return 'A data inicial não pode ser maior que a data final.';
    }

    try {
      await _firestore.collection('bloqueios_agenda').add({
        'motivo': motivo.trim().isEmpty ? 'Agenda bloqueada' : motivo.trim(),
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return 'Erro ao criar bloqueio de agenda.';
    }
  }

  Future<String?> excluirBloqueioAgenda(String bloqueioId) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode excluir bloqueios.';
    }

    try {
      await _firestore.collection('bloqueios_agenda').doc(bloqueioId).delete();
      return null;
    } catch (e) {
      return 'Erro ao excluir bloqueio.';
    }
  }

  Future<String?> agendarHorario({
    required String servico,
    required String data,
    required String horario,
    required String formaPagamento,
  }) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return 'Usuário não autenticado.';
    }

    final dataBloqueada = await existeBloqueioParaData(data);

    if (dataBloqueada) {
      return 'A barbearia não atenderá nesta data.';
    }

    final idAgendamento = gerarIdAgendamento(data, horario);
    final idHorario = gerarIdHorario(data, horario);

    final agendamentoRef = _firestore
        .collection('agendamentos')
        .doc(idAgendamento);
    final vagaRef = _firestore.collection('vagas_agenda').doc(idHorario);

    final valor = valorServico(servico);

    String statusPagamento = 'Pendente';

    if (formaPagamento == 'Pix') {
      statusPagamento = 'Aguardando confirmação';
    } else {
      statusPagamento = 'Pendente - pagar no local';
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final configSnapshot = await transaction.get(_configAgendaRef);
        final configDados = configSnapshot.data();

        final horariosPermitidos = extrairHorarios(configDados);
        final diasFuncionamento = extrairDiasFuncionamento(configDados);
        final chaveDia = chaveDiaSemanaPorData(data);

        if (diasFuncionamento[chaveDia] != true) {
          throw Exception('A barbearia não atende neste dia da semana.');
        }

        if (!horariosPermitidos.contains(horario)) {
          throw Exception('Este horário não está disponível.');
        }

        final agendamentoSnapshot = await transaction.get(agendamentoRef);

        if (agendamentoSnapshot.exists) {
          throw Exception('Você já possui agendamento neste horário.');
        }

        final vagaSnapshot = await transaction.get(vagaRef);
        final vagaDados = vagaSnapshot.data();

        final quantidadeAtual = vagaDados == null
            ? 0
            : ((vagaDados['quantidade'] ?? 0) as num).toInt();

        if (quantidadeAtual >= capacidadePorHorario) {
          throw Exception('Este horário já está lotado.');
        }

        transaction.set(agendamentoRef, {
          'usuarioId': usuario.uid,
          'nomeCliente': usuario.displayName ?? 'Cliente',
          'emailCliente': usuario.email ?? '',
          'servico': servico,
          'data': data,
          'horario': horario,
          'valor': valor,
          'formaPagamento': formaPagamento,
          'statusPagamento': statusPagamento,
          'statusAgendamento': 'ativo',
          'criadoEm': FieldValue.serverTimestamp(),
        });

        transaction.set(vagaRef, {
          'data': data,
          'horario': horario,
          'quantidade': quantidadeAtual + 1,
          'capacidade': capacidadePorHorario,
          'atualizadoEm': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      return null;
    } catch (e) {
      if (e.toString().contains('Este horário já está lotado')) {
        return 'Este horário já está lotado.';
      }

      if (e.toString().contains('Você já possui agendamento')) {
        return 'Você já possui agendamento neste horário.';
      }

      if (e.toString().contains('Este horário não está disponível')) {
        return 'Este horário não está disponível.';
      }

      if (e.toString().contains('não atende neste dia')) {
        return 'A barbearia não atende neste dia da semana.';
      }

      return 'Erro ao marcar horário. Tente novamente.';
    }
  }

  Future<String?> cancelarAgendamento(String agendamentoId) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return 'Usuário não autenticado.';
    }

    final agendamentoRef = _firestore
        .collection('agendamentos')
        .doc(agendamentoId);

    final notificacaoRef = _firestore.collection('notificacoes_dono').doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final agendamentoSnapshot = await transaction.get(agendamentoRef);

        if (!agendamentoSnapshot.exists) {
          throw Exception('Agendamento não encontrado.');
        }

        final dados = agendamentoSnapshot.data()!;

        final dono = usuarioEhDono(usuario);
        final usuarioIdAgendamento = dados['usuarioId'] ?? '';

        if (!dono && usuarioIdAgendamento != usuario.uid) {
          throw Exception(
            'Você não tem permissão para cancelar este agendamento.',
          );
        }

        final statusAgendamento = (dados['statusAgendamento'] ?? 'ativo')
            .toString();

        if (statusAgendamento == 'cancelado') {
          throw Exception('Este agendamento já foi cancelado.');
        }

        if (statusAgendamento == 'concluido') {
          throw Exception('Este atendimento já foi concluído.');
        }

        final data = dados['data'] ?? '';
        final horario = dados['horario'] ?? '';
        final idHorario = gerarIdHorario(data, horario);
        final vagaRef = _firestore.collection('vagas_agenda').doc(idHorario);

        final vagaSnapshot = await transaction.get(vagaRef);
        final vagaDados = vagaSnapshot.data();

        final quantidadeAtual = vagaDados == null
            ? 0
            : ((vagaDados['quantidade'] ?? 0) as num).toInt();

        final novaQuantidade = quantidadeAtual > 0 ? quantidadeAtual - 1 : 0;

        transaction.set(vagaRef, {
          'data': data,
          'horario': horario,
          'quantidade': novaQuantidade,
          'capacidade': capacidadePorHorario,
          'atualizadoEm': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.update(agendamentoRef, {
          'statusAgendamento': 'cancelado',
          'canceladoEm': FieldValue.serverTimestamp(),
          'canceladoPor': dono ? 'dono' : 'cliente',
        });

        if (!dono) {
          transaction.set(notificacaoRef, {
            'tipo': 'cancelamento',
            'titulo': 'Agendamento cancelado',
            'mensagem':
                '${dados['nomeCliente'] ?? 'Cliente'} cancelou ${dados['servico'] ?? 'serviço'} no dia $data às $horario.',
            'nomeCliente': dados['nomeCliente'] ?? 'Cliente',
            'emailCliente': dados['emailCliente'] ?? '',
            'servico': dados['servico'] ?? '',
            'data': data,
            'horario': horario,
            'lida': false,
            'criadoEm': FieldValue.serverTimestamp(),
          });
        }
      });

      return null;
    } catch (e) {
      if (e.toString().contains('Agendamento não encontrado')) {
        return 'Agendamento não encontrado.';
      }

      if (e.toString().contains('permissão')) {
        return 'Você não tem permissão para cancelar este agendamento.';
      }

      if (e.toString().contains('já foi cancelado')) {
        return 'Este agendamento já foi cancelado.';
      }

      if (e.toString().contains('já foi concluído')) {
        return 'Este atendimento já foi concluído.';
      }

      return 'Erro ao cancelar agendamento.';
    }
  }

  Future<String?> confirmarPagamento(String agendamentoId) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode confirmar pagamentos.';
    }

    final agendamentoRef = _firestore
        .collection('agendamentos')
        .doc(agendamentoId);

    try {
      final snapshot = await agendamentoRef.get();

      if (!snapshot.exists) {
        return 'Agendamento não encontrado.';
      }

      final dados = snapshot.data();
      final statusAgendamento = (dados?['statusAgendamento'] ?? 'ativo')
          .toString();

      if (statusAgendamento == 'cancelado') {
        return 'Não é possível confirmar pagamento de um agendamento cancelado.';
      }

      await agendamentoRef.update({
        'statusPagamento': 'Pago',
        'pagoEm': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return 'Erro ao confirmar pagamento.';
    }
  }

  Future<String?> marcarNotificacaoComoLida(String notificacaoId) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode alterar notificações.';
    }

    try {
      await _firestore
          .collection('notificacoes_dono')
          .doc(notificacaoId)
          .update({'lida': true});

      return null;
    } catch (e) {
      return 'Erro ao marcar notificação como lida.';
    }
  }

  Future<String?> concluirAtendimento(String agendamentoId) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode concluir atendimentos.';
    }

    final agendamentoRef = _firestore
        .collection('agendamentos')
        .doc(agendamentoId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(agendamentoRef);

        if (!snapshot.exists) {
          throw Exception('Agendamento não encontrado.');
        }

        final dados = snapshot.data()!;
        final statusAgendamento = (dados['statusAgendamento'] ?? 'ativo')
            .toString();

        if (statusAgendamento == 'cancelado') {
          throw Exception('Não é possível concluir um agendamento cancelado.');
        }

        if (statusAgendamento == 'concluido') {
          throw Exception('Este atendimento já foi concluído.');
        }

        transaction.update(agendamentoRef, {
          'statusAgendamento': 'concluido',
          'concluidoEm': FieldValue.serverTimestamp(),
        });
      });

      return null;
    } catch (e) {
      if (e.toString().contains('cancelado')) {
        return 'Não é possível concluir um agendamento cancelado.';
      }

      if (e.toString().contains('já foi concluído')) {
        return 'Este atendimento já foi concluído.';
      }

      return 'Erro ao concluir atendimento.';
    }
  }
}
