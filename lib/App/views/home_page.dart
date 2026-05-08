import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/agendamento_service.dart';
import 'agendamento_page.dart';
import 'login_page.dart';
import 'meus_agendamentos_page.dart';
import 'painel_dono_page.dart';

class HomePage extends StatelessWidget {
  final User? usuario;

  const HomePage({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final String nomeOuEmail =
        usuario?.displayName ?? usuario?.email ?? 'usuário';

    final AgendamentoService service = AgendamentoService();
    final bool ehDono = service.usuarioEhDono(usuario);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Barbearia',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFD4A853)),
            tooltip: 'Sair',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A853).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4A853), width: 2),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 56,
                  color: Color(0xFFD4A853),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Bem-vindo à Home!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Olá, $nomeOuEmail 👋',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD4A853), fontSize: 18),
              ),

              const SizedBox(height: 18),

              const Text(
                'Escolha um serviço para marcar seu horário',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 42),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _servicoCard(context, Icons.content_cut, 'Corte'),
                  _servicoCard(context, Icons.face_retouching_natural, 'Barba'),
                  _servicoCard(context, Icons.star_outline, 'Combo'),
                ],
              ),

              const SizedBox(height: 36),

              _botaoGrande(
                context: context,
                icon: Icons.event_note,
                texto: 'Meus agendamentos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MeusAgendamentosPage()),
                  );
                },
              ),

              if (ehDono) ...[
                const SizedBox(height: 14),
                _botaoGrande(
                  context: context,
                  icon: Icons.admin_panel_settings_outlined,
                  texto: 'Painel do dono',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PainelDonoPage()),
                    );
                  },
                ),
              ],

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3C3C3C)),
                ),
                child: const Text(
                  'Após escolher um serviço, você poderá selecionar uma data e um horário disponível.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _servicoCard(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AgendamentoPage(servico: label)),
        );
      },
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3C3C3C)),
            ),
            child: Icon(icon, color: const Color(0xFFD4A853), size: 34),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _botaoGrande({
    required BuildContext context,
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFFD4A853)),
        label: Text(
          texto,
          style: const TextStyle(
            color: Color(0xFFD4A853),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD4A853)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
