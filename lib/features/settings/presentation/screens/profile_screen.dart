import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: AppPage(
          child: StreamBuilder<AppProfile?>(
            stream: ref.watch(appRepositoryProvider).watchProfile(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LoadingView();
              final profile = snapshot.data!;
              final name = [profile.firstName, profile.lastName]
                  .whereType<String>()
                  .join(' ');
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 31,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              name.characters.first.toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  profile.email ?? 'Perfil guardado localmente',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar perfil',
                            onPressed: () =>
                                context.push(RouteNames.editProfile),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Organización'),
                  _menu(
                    context,
                    Icons.groups_outlined,
                    'Grupos y gastos compartidos',
                    RouteNames.groups,
                  ),
                  _menu(
                    context,
                    Icons.insights_outlined,
                    'Estadísticas',
                    RouteNames.statistics,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Datos y seguridad'),
                  _menu(
                    context,
                    Icons.backup_outlined,
                    'Respaldo local',
                    RouteNames.backup,
                  ),
                  _menu(
                    context,
                    Icons.restore_rounded,
                    'Restaurar respaldo',
                    RouteNames.restore,
                  ),
                  _menu(
                    context,
                    Icons.lock_outline_rounded,
                    'Seguridad',
                    RouteNames.security,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Información'),
                  _menu(
                    context,
                    Icons.help_outline_rounded,
                    'Ayuda',
                    RouteNames.help,
                  ),
                  _menu(
                    context,
                    Icons.shield_outlined,
                    'Privacidad',
                    RouteNames.privacy,
                  ),
                  _menu(
                    context,
                    Icons.description_outlined,
                    'Términos de uso',
                    RouteNames.terms,
                  ),
                ],
              );
            },
          ),
        ),
      );
  Widget _menu(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: ListTile(
            onTap: () => context.push(route),
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      );
}
