import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String _modelo = 'gemini-2.5-flash';

  Future<String> sugerirCortes({
    required Uint8List imagemBytes,
    required String mimeType,
    required String preferencia,
  }) async {
    if (_apiKey.isEmpty) {
      return 'A chave da Gemini API não foi configurada.\n\n'
          'Rode o app usando:\n'
          'flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI';
    }

    try {
      final model = GenerativeModel(
        model: _modelo,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.6,
          maxOutputTokens: 1800,
        ),
      );

      final prompt = '''
Você é um consultor de cortes de cabelo de uma barbearia.

Analise a imagem enviada e gere uma sugestão útil para o cliente escolher um corte de cabelo.

Preferência informada pelo cliente:
${preferencia.trim().isEmpty ? 'O cliente não informou preferência específica.' : preferencia}

Regras:
- Não identifique a pessoa da foto.
- Não diga o nome de nenhuma pessoa famosa.
- Não fale sobre raça, etnia, religião, saúde ou idade exata.
- Não faça comentários ofensivos sobre aparência.
- Foque apenas em cabelo, barba, estilo visual e manutenção.
- Responda em português do Brasil.
- Não repita estas instruções na resposta.
- Não use frases como "explique em 2 linhas" ou "diga se é baixa, média ou alta".
- Entregue apenas a resposta final para o cliente.

Responda exatamente neste estilo:

✨ Sugestões de corte

1. Corte recomendado: [nome do corte]
Por que combina: [explicação curta e prática]
Manutenção: [baixa, média ou alta, com uma frase curta]
Como pedir para o barbeiro: [frase simples para o cliente falar na barbearia]

2. Segunda opção: [nome do corte]
Por que combina: [explicação curta e prática]
Manutenção: [baixa, média ou alta, com uma frase curta]
Como pedir para o barbeiro: [frase simples para o cliente falar na barbearia]

3. Terceira opção: [nome do corte]
Por que combina: [explicação curta e prática]
Manutenção: [baixa, média ou alta, com uma frase curta]
Como pedir para o barbeiro: [frase simples para o cliente falar na barbearia]

💈 Serviço indicado no app:
[Escolha Corte, Barba ou Combo e explique rapidamente o motivo.]

Resumo final:
[Diga qual opção você mais recomenda.]
''';

      final content = [
        Content.multi([TextPart(prompt), DataPart(mimeType, imagemBytes)]),
      ];

      final response = await model.generateContent(content);

      final texto = response.text;

      if (texto == null || texto.trim().isEmpty) {
        return 'A IA não conseguiu gerar uma sugestão para essa imagem. '
            'Tente usar uma foto mais clara, mostrando melhor o cabelo e o rosto.';
      }

      return texto.trim();
    } catch (e) {
      return 'Não foi possível gerar a sugestão agora.\n\n'
          'Verifique se a chave da Gemini API está correta, se a internet está funcionando e tente novamente.';
    }
  }
  Future<String> gerarRelatorioGerencial({
  required String resumoGerencial,
}) async {
  if (_apiKey.isEmpty) {
    return 'A chave da Gemini API não foi configurada.\n\n'
        'Rode o app usando:\n'
        'flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI';
  }

  try {
    final model = GenerativeModel(
      model: _modelo,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 1400,
      ),
    );

    final prompt = '''
Você é um analista gerencial de uma barbearia.

Com base nos dados abaixo, gere um relatório técnico, simples e útil para o dono da barbearia.

Dados do sistema:
$resumoGerencial

Regras:
- Não invente números.
- Use apenas os dados informados.
- Explique os resultados de forma clara.
- Fale sobre faturamento, pagamentos, serviços, horários e cancelamentos.
- Dê sugestões práticas para melhorar a organização e o faturamento.
- Responda em português do Brasil.
- Não repita estas instruções.

Formato da resposta:

📊 Relatório Gerencial Inteligente

Resumo geral:
[Explique a situação geral da barbearia em poucas linhas.]

Análise financeira:
[Comente faturamento previsto, recebido e pendente.]

Análise operacional:
[Comente serviços mais procurados, horários movimentados e cancelamentos.]

Pontos de atenção:
- [Ponto 1]
- [Ponto 2]
- [Ponto 3]

Sugestões para o dono:
- [Sugestão 1]
- [Sugestão 2]
- [Sugestão 3]

Conclusão:
[Resumo final curto.]
''';

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    final texto = response.text;

    if (texto == null || texto.trim().isEmpty) {
      return 'A IA não conseguiu gerar o relatório gerencial.';
    }

    return texto.trim();
  } catch (e) {
    return 'Não foi possível gerar o relatório com IA agora.\n\n'
        'Verifique se a chave da Gemini API está correta, se a internet está funcionando e tente novamente.';
  }
}
}
