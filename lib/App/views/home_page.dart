import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/agendamento_service.dart';
import '../services/status_service.dart';
import 'agendamento_page.dart';
import 'login_page.dart';
import 'meus_agendamentos_page.dart';
import 'painel_dono_page.dart';
import 'postar_status_page.dart';
import 'ver_status_page.dart';
import 'consultor_ia_page.dart';

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
                width: 118,
                height: 118,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A853).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4A853), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.content_cut,
                        size: 56,
                        color: Color(0xFFD4A853),
                      );
                    },
                  ),
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

              const SizedBox(height: 30),

              _statusBarbearia(context, ehDono),

              const SizedBox(height: 30),

              _botaoGrande(
                context: context,
                icon: Icons.auto_awesome,
                texto: 'Consultor de Corte com IA',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConsultorIaPage()),
                  );
                },
              ),

              const SizedBox(height: 30),

              const Text(
                'Escolha um serviço para marcar seu horário',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 32),

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
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBarbearia(BuildContext context, bool ehDono) {
    final StatusService statusService = StatusService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Status da Barbearia',
            style: TextStyle(
              color: Color(0xFFD4A853),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 112,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: statusService.buscarStatusAtivos(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              docs.sort((a, b) {
                final criadoA = a.data()['criadoEm'];
                final criadoB = b.data()['criadoEm'];

                if (criadoA is Timestamp && criadoB is Timestamp) {
                  return criadoB.compareTo(criadoA);
                }

                return 0;
              });

              if (!ehDono && docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3C3C3C)),
                  ),
                  child: const Center(
                    child: Text(
                      'Nenhum status publicado ainda.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }

              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (ehDono) _botaoAdicionarStatus(context),
                  ...docs.map((doc) {
                    final dados = doc.data();

                    final titulo = dados['titulo'] ?? 'Status';
                    final legenda = dados['legenda'] ?? '';
                    final imagemAsset =
                        dados['imagemAsset'] ?? 'assets/logo.png';

                    return _statusItem(
                      context: context,
                      statusId: doc.id,
                      titulo: titulo,
                      legenda: legenda,
                      imagemAsset: imagemAsset,
                      podeExcluir: ehDono,
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _botaoAdicionarStatus(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostarStatusPage()),
        );
      },
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2C2C2C),
                border: Border.all(color: const Color(0xFFD4A853), width: 2),
              ),
              child: const Icon(Icons.add, color: Color(0xFFD4A853), size: 36),
            ),
            const SizedBox(height: 8),
            const Text(
              'Postar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFD4A853), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusItem({
    required BuildContext context,
    required String statusId,
    required String titulo,
    required String legenda,
    required String imagemAsset,
    required bool podeExcluir,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerStatusPage(
              statusId: statusId,
              titulo: titulo,
              legenda: legenda,
              imagemAsset: imagemAsset,
              podeExcluir: podeExcluir,
            ),
          ),
        );
      },
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4A853), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagemAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFF2C2C2C),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
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
