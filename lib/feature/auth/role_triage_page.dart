import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/data/firebase_repository.dart';
import '../perfil/perfil_screen.dart';
import 'login_page.dart';

class RoleTriagePage extends StatelessWidget {
  const RoleTriagePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: Color(0xFF087E8B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Aguardando atribuição de cargo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17212B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Seu cadastro foi realizado com sucesso. Agora sua conta está em triagem e só será liberada após um integrante com cargo de Presidência ou Vice-Presidência definir seu cargo e papel dentro da organização.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF6E7A86),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF7F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD8E8EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dados do cadastro',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17212B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(label: 'Nome', value: profile.name),
                            _InfoRow(label: 'E-mail', value: profile.email),
                            _InfoRow(
                              label: 'Status',
                              value: Hierarchy.awaitingRoleAssignment,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await FirebaseRepository.instance.saveProfile(
                              profile.copyWith(
                                role: Hierarchy.awaitingRoleAssignment,
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cadastro em triagem. Aguarde a liberação do cargo.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Atualizar status'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sair'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF6E7A86),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF17212B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
