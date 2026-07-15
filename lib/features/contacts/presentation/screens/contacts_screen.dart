import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});
  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(appRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'contactFab',
        onPressed: () => context.push('/contacts/new'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Agregar'),
      ),
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar contactos',
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Contact>>(
                stream: repository.watchContacts(query: _query),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorState(message: '${snapshot.error}');
                  }
                  if (!snapshot.hasData) return const LoadingView();
                  final contacts = snapshot.data!;
                  if (contacts.isEmpty) {
                    return EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: _query.isEmpty
                          ? 'Tu agenda está vacía'
                          : 'Sin resultados',
                      message: _query.isEmpty
                          ? 'Agrega personas para asociarlas a préstamos, deudas y grupos.'
                          : 'No encontramos un contacto con ese nombre.',
                      actionLabel: _query.isEmpty ? 'Agregar contacto' : null,
                      onAction: _query.isEmpty
                          ? () => context.push('/contacts/new')
                          : null,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final name = _name(contact);
                      return Card(
                        child: ListTile(
                          onTap: () => context.push('/contacts/${contact.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              name.characters.first.toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            contact.alias ??
                                contact.phone ??
                                contact.email ??
                                'Contacto local',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({this.contactId, super.key});
  final String? contactId;
  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _form = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _alias = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    if (widget.contactId != null) _load();
  }

  Future<void> _load() async {
    final contact =
        await ref.read(appRepositoryProvider).getContact(widget.contactId!);
    if (!mounted || contact == null) return;
    setState(() {
      _firstName.text = contact.firstName;
      _lastName.text = contact.lastName ?? '';
      _alias.text = contact.alias ?? '';
      _phone.text = contact.phone ?? '';
      _email.text = contact.email ?? '';
      _notes.text = contact.notes ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _alias,
      _phone,
      _email,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contactId != null && !_loaded) {
      return const Scaffold(body: LoadingView());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contactId == null ? 'Nuevo contacto' : 'Editar contacto',
        ),
      ),
      body: AppPage(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alias,
                decoration: const InputDecoration(
                  labelText: 'Apodo (opcional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo (opcional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty && !v.contains('@')
                        ? 'Correo inválido'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Guardar contacto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(appRepositoryProvider).saveContact(
            id: widget.contactId,
            firstName: _firstName.text,
            lastName: _lastName.text,
            alias: _alias.text,
            phone: _phone.text,
            email: _email.text,
            notes: _notes.text,
          );
      if (mounted) {
        showMessage(context, 'Contacto guardado');
        context.go('/contacts/$id');
      }
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({required this.contactId, super.key});
  final String contactId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<Contact?>(
        future: ref.read(appRepositoryProvider).getContact(contactId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: LoadingView());
          final contact = snapshot.data!;
          final name = _name(contact);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Contacto'),
              actions: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => context.push('/contacts/${contact.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            body: AppPage(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            name.characters.first.toUpperCase(),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (contact.alias != null)
                          Text(
                            contact.alias!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/debts/new?contactId=${contact.id}&contactName=${Uri.encodeComponent(name)}',
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear deuda con este contacto'),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Column(
                      children: [
                        if (contact.phone != null)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Teléfono'),
                            subtitle: Text(contact.phone!),
                          ),
                        if (contact.email != null)
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Correo'),
                            subtitle: Text(contact.email!),
                          ),
                        if (contact.notes != null)
                          ListTile(
                            leading: const Icon(Icons.notes_outlined),
                            title: const Text('Notas'),
                            subtitle: Text(contact.notes!),
                          ),
                        if (contact.phone == null &&
                            contact.email == null &&
                            contact.notes == null)
                          const Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('No hay información adicional.'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await confirmAction(
                        context,
                        title: 'Archivar contacto',
                        message:
                            'El contacto dejará de aparecer en la agenda, pero sus deudas se conservarán.',
                        confirmLabel: 'Archivar',
                      )) {
                        await ref
                            .read(appRepositoryProvider)
                            .archiveContact(contact);
                        if (context.mounted) context.go('/contacts');
                      }
                    },
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archivar contacto'),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

String _name(Contact contact) =>
    [contact.firstName, contact.lastName].whereType<String>().join(' ');
