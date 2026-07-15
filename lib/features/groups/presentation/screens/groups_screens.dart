import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Grupos')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/groups/new'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo grupo'),
        ),
        body: AppPage(
          child: StreamBuilder<List<Group>>(
            stream: ref.watch(appRepositoryProvider).watchGroups(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(message: '${snapshot.error}');
              }
              if (!snapshot.hasData) return const LoadingView();
              final groups = snapshot.data!;
              if (groups.isEmpty) {
                return EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No tienes grupos',
                  message:
                      'Crea un grupo para dividir gastos entre varias personas sin perder el control.',
                  actionLabel: 'Crear grupo',
                  onAction: () => context.push('/groups/new'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return Card(
                    child: ListTile(
                      onTap: () => context.push('/groups/${group.id}'),
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.groups_rounded),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(group.description ?? 'Gasto compartido'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMinor(
                              group.totalAmountInMinorUnits,
                              group.currencyCode,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}

class GroupFormScreen extends ConsumerStatefulWidget {
  const GroupFormScreen({super.key});
  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _currency = 'DOP';
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nuevo grupo')),
        body: AppPage(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Escribe un nombre'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Moneda'),
                  items: const ['DOP', 'USD', 'EUR']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _currency = value!,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Crear grupo'),
                ),
              ],
            ),
          ),
        ),
      );
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(appRepositoryProvider).createGroup(
            name: _name.text,
            currency: _currency,
            description: _description.text,
          );
      if (mounted) context.go('/groups/$id');
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<Group?>(
        future: ref.read(appRepositoryProvider).getGroup(groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: LoadingView());
          final group = snapshot.data!;
          return Scaffold(
            appBar: AppBar(title: Text(group.name)),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addParticipant(context, ref, group),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Participante'),
            ),
            body: AppPage(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total asignado',
                          style: TextStyle(color: Colors.white.withAlpha(190)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatMinor(
                            group.totalAmountInMinorUnits,
                            group.currencyCode,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        if (group.description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            group.description!,
                            style:
                                TextStyle(color: Colors.white.withAlpha(210)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Participantes'),
                  StreamBuilder<List<GroupParticipant>>(
                    stream: ref
                        .watch(appRepositoryProvider)
                        .watchGroupParticipants(group.id),
                    builder: (context, participantSnapshot) {
                      if (!participantSnapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final participants = participantSnapshot.data!;
                      if (participants.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text(
                              'Agrega participantes y asigna cuánto corresponde a cada uno.',
                            ),
                          ),
                        );
                      }
                      return Card(
                        child: Column(
                          children: participants
                              .map(
                                (participant) => ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      participant
                                          .contactNameSnapshot.characters.first
                                          .toUpperCase(),
                                    ),
                                  ),
                                  title: Text(participant.contactNameSnapshot),
                                  subtitle: Text(
                                    participant.status == 'pending'
                                        ? 'Pendiente'
                                        : participant.status,
                                  ),
                                  trailing: Text(
                                    formatMinor(
                                      participant.outstandingAmountInMinorUnits,
                                      group.currencyCode,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
  Future<void> _addParticipant(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar participante'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Monto (${group.currencyCode})',
                ),
                validator: (v) {
                  final parsed = parseMoney(v ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Monto inválido'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref.read(appRepositoryProvider).addGroupParticipant(
            group: group,
            name: name.text,
            amount: parseMoney(amount.text)!,
          );
      if (context.mounted) showMessage(context, 'Participante agregado');
    }
    name.dispose();
    amount.dispose();
  }
}
