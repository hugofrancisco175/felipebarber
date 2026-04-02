import '../models/usuario_model.dart';

class UsuarioMockStore {
  // Singleton
  static final UsuarioMockStore _instance = UsuarioMockStore._internal();
  factory UsuarioMockStore() => _instance;
  UsuarioMockStore._internal();

  // Lista de usuários em memória com um usuário mockado padrão
  final List<UsuarioModel> _usuarios = [
    UsuarioModel(nome: 'Admin', email: 'admin@barbearia.com', senha: '123456'),
  ];

  List<UsuarioModel> get usuarios => List.unmodifiable(_usuarios);

  void adicionar(UsuarioModel usuario) {
    _usuarios.add(usuario);
  }

  /// Retorna o usuário se email e senha baterem, null caso contrário
  UsuarioModel? autenticar(String email, String senha) {
    try {
      return _usuarios.firstWhere(
        (u) => u.email == email.trim() && u.senha == senha,
      );
    } catch (_) {
      return null;
    }
  }

  bool emailJaCadastrado(String email) {
    return _usuarios.any((u) => u.email == email.trim());
  }
}
