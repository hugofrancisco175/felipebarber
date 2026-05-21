import 'package:flutter_test/flutter_test.dart';
import 'package:app_login/app/services/agendamento_service.dart';

void main() {
  group('AgendamentoService - Testes de unidade', () {
    late AgendamentoService service;

    setUp(() {
      service = AgendamentoService();
    });

    test('CT01 - Deve retornar valor 40 para serviço Corte', () {
      final valor = service.valorServico('Corte');

      expect(valor, 40.0);
    });

    test('CT02 - Deve retornar valor 20 para serviço Barba', () {
      final valor = service.valorServico('Barba');

      expect(valor, 20.0);
    });

    test('CT03 - Deve retornar valor 60 para serviço Combo', () {
      final valor = service.valorServico('Combo');

      expect(valor, 60.0);
    });

    test('CT04 - Deve formatar valor em reais', () {
      final valorFormatado = service.formatarValor(40.0);

      expect(valorFormatado, 'R\$ 40,00');
    });

    test('CT05 - Deve gerar ID do horário corretamente', () {
      final id = service.gerarIdHorario('2026-05-19', '09:00');

      expect(id, '2026-05-19_09-00');
    });

    test('CT06 - Deve identificar terça-feira pela data', () {
      final dia = service.chaveDiaSemanaPorData('2026-05-19');

      expect(dia, 'terca');
    });

    test('CT07 - Deve retornar nome do dia da semana pela chave', () {
      final nomeDia = service.nomeDiaSemanaPorChave('segunda');

      expect(nomeDia, 'Segunda-feira');
    });

    test('CT08 - Deve retornar capacidade máxima igual a 3', () {
      expect(AgendamentoService.capacidadePorHorario, 3);
    });

    test('CT09 - Deve retornar horários padrão quando não houver configuração', () {
      final horarios = service.extrairHorarios(null);

      expect(horarios, contains('09:00'));
      expect(horarios, contains('18:00'));
      expect(horarios.length, 9);
    });

    test('CT10 - Deve ordenar horários vindos da configuração', () {
      final horarios = service.extrairHorarios({
        'horariosDisponiveis': ['15:00', '09:00', '13:00'],
      });

      expect(horarios, ['09:00', '13:00', '15:00']);
    });

    test('CT11 - Domingo deve vir fechado por padrão', () {
      final dias = service.extrairDiasFuncionamento(null);

      expect(dias['domingo'], false);
    });

    test('CT12 - Deve alterar dias de funcionamento com base na configuração', () {
      final dias = service.extrairDiasFuncionamento({
        'diasFuncionamento': {
          'segunda': false,
          'domingo': true,
        },
      });

      expect(dias['segunda'], false);
      expect(dias['domingo'], true);
    });
  });
}