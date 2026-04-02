import 'package:flutter/material.dart';

class SplashViewModel {
  /// Aguarda [segundos] e navega para a rota informada
  void iniciarNavegacao(BuildContext context, Widget destino) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    });
  }
}
