import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String emailDono = 'felipebarber@gmail.com';

  static const List<Map<String, String>> imagensDisponiveis = [
    {
      'nome': 'Promoção',
      'asset': 'assets/status/promocao.jpg',
    },
    {
      'nome': 'Corte',
      'asset': 'assets/status/corte.jpg',
    },
    {
      'nome': 'Aviso',
      'asset': 'assets/status/aviso.jpg',
    },
  ];

  bool usuarioEhDono(User? usuario) {
    return usuario?.email?.toLowerCase() == emailDono.toLowerCase();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buscarStatusAtivos() {
    return _firestore
        .collection('status_barbearia')
        .where('ativo', isEqualTo: true)
        .snapshots();
  }

  Future<String?> postarStatus({
    required String titulo,
    required String legenda,
    required String imagemAsset,
  }) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode postar status.';
    }

    if (titulo.trim().isEmpty) {
      return 'Informe um título.';
    }

    if (legenda.trim().isEmpty) {
      return 'Informe uma legenda.';
    }

    try {
      await _firestore.collection('status_barbearia').add({
        'titulo': titulo.trim(),
        'legenda': legenda.trim(),
        'imagemAsset': imagemAsset,
        'ativo': true,
        'donoEmail': usuario?.email ?? '',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return 'Erro ao postar status.';
    }
  }

  Future<String?> excluirStatus(String statusId) async {
    final usuario = _auth.currentUser;

    if (!usuarioEhDono(usuario)) {
      return 'Apenas o dono pode excluir status.';
    }

    try {
      await _firestore.collection('status_barbearia').doc(statusId).update({
        'ativo': false,
      });

      return null;
    } catch (e) {
      return 'Erro ao excluir status.';
    }
  }
}