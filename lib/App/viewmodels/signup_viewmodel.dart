import '../data/usuario_mock_store.dart';
import '../models/usuario_model.dart';

class SignupViewModel {
  final UsuarioMockStore _store = UsuarioMockStore();

  /// Retorna null em caso de sucesso ou uma mensagem de erro
  String? cadastrar(String nome, String email, String senha) {
    if (_store.emailJaCadastrado(email)) {
      return 'Este e-mail já está cadastrado.';
    }
    _store.adicionar(UsuarioModel(nome: nome, email: email, senha: senha));
    return null;
  }

  String? validarNome(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu nome';
    if (value.trim().length < 3) return 'Nome muito curto';
    return null;
  }

  String? validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    if (!value.contains('@')) return 'E-mail inválido';
    return null;
  }

  String? validarSenha(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha';
    if (value.length < 6) return 'Senha deve ter no mínimo 6 caracteres';
    return null;
  }

  String? validarConfirmacaoSenha(String? value, String senha) {
    if (value == null || value.isEmpty) return 'Confirme a senha';
    if (value != senha) return 'As senhas não coincidem';
    return null;
  }
}
