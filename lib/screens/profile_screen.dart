import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// Autor: Roberto
// Pestaña "Perfil": muestra el usuario y rol actuales y permite cerrar sesión.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  IconData _iconFor(UserRole role) {
    switch (role) {
      case UserRole.cliente:
        return Icons.person_outline;
      case UserRole.dueno:
        return Icons.store_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final role = appState.currentRole;
    final name = appState.currentUserName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.headerBackground,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accent,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    if (role != null)
                      Text(role.label, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (role != null)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(_iconFor(role), color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            role.description,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (appState.currentUsername != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Usuario: ${appState.currentUsername}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Para probar otro rol, cierra sesión y entra con otra '
                'cuenta (o crea una nueva desde "Crear cuenta" en el '
                'login, eligiendo Cliente o Dueño de tienda).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => appState.logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.favorite,
                    side: const BorderSide(color: AppColors.favorite),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
