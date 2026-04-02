import '../data/usuario_mock_store.dart';
import '../models/usuario_model.dart';

class LoginViewModel {
  final UsuarioMockStore _store = UsuarioMockStore();

  /// Retorna o usuário autenticado ou null se as credenciais forem inválidas
  UsuarioModel? login(String email, String senha) {
    return _store.autenticar(email, senha);
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
}
