import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inicializado = false;

  static Future<void> inicializar() async {
    if (_inicializado) return;

    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    await _pedirPermissaoAndroid();

    _inicializado = true;
  }

  static Future<void> _pedirPermissaoAndroid() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  static int _gerarIdNotificacao(String agendamentoId, int tipo) {
    int hash = tipo;

    for (final codigo in agendamentoId.codeUnits) {
      hash = ((hash * 31) + codigo) & 0x7fffffff;
    }

    return hash;
  }

  static DateTime? _converterParaDateTime(String data, String horario) {
    try {
      final partesData = data.split('-');
      final partesHorario = horario.split(':');

      final ano = int.parse(partesData[0]);
      final mes = int.parse(partesData[1]);
      final dia = int.parse(partesData[2]);

      final hora = int.parse(partesHorario[0]);
      final minuto = int.parse(partesHorario[1]);

      return DateTime(ano, mes, dia, hora, minuto);
    } catch (_) {
      return null;
    }
  }

  static Future<void> agendarNotificacoesAgendamento({
    required String agendamentoId,
    required String servico,
    required String data,
    required String horario,
  }) async {
    await inicializar();

    final dataHoraAgendamento = _converterParaDateTime(data, horario);

    if (dataHoraAgendamento == null) return;

    final agora = DateTime.now();

    final notificacaoDia = DateTime(
      dataHoraAgendamento.year,
      dataHoraAgendamento.month,
      dataHoraAgendamento.day,
      8,
      0,
    );

    final notificacaoTrintaMinAntes = dataHoraAgendamento.subtract(
      const Duration(minutes: 30),
    );

    if (notificacaoDia.isAfter(agora)) {
      await _agendar(
        id: _gerarIdNotificacao(agendamentoId, 1),
        titulo: 'Lembrete de agendamento',
        corpo: 'Você tem $servico hoje às $horario na barbearia.',
        dataHora: notificacaoDia,
        payload: agendamentoId,
      );
    }

    if (notificacaoTrintaMinAntes.isAfter(agora)) {
      await _agendar(
        id: _gerarIdNotificacao(agendamentoId, 2),
        titulo: 'Seu horário está chegando',
        corpo: 'Seu $servico é daqui 30 minutos, às $horario.',
        dataHora: notificacaoTrintaMinAntes,
        payload: agendamentoId,
      );
    }
  }

  static Future<void> _agendar({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataHora,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'agendamentos_barbearia',
      'Agendamentos da Barbearia',
      channelDescription: 'Lembretes dos horários marcados na barbearia',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final dataHoraComFuso = tz.TZDateTime.from(dataHora, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: titulo,
      body: corpo,
      scheduledDate: dataHoraComFuso,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  static Future<void> cancelarNotificacoesAgendamento(
    String agendamentoId,
  ) async {
    await inicializar();

    await _plugin.cancel(id: _gerarIdNotificacao(agendamentoId, 1));

    await _plugin.cancel(id: _gerarIdNotificacao(agendamentoId, 2));
  }

  static Future<void> mostrarNotificacaoTeste() async {
    await inicializar();

    const androidDetails = AndroidNotificationDetails(
      'teste_barbearia',
      'Teste Barbearia',
      channelDescription: 'Canal para testar notificações',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: 99999,
      title: 'Teste de notificação',
      body: 'As notificações do app estão funcionando.',
      notificationDetails: details,
    );
  }
}
