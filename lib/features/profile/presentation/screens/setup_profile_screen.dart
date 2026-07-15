import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({this.editing = false, super.key});
  final bool editing;
  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _currency = 'DOP';
  bool _saving = false;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    if (widget.editing) _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(appRepositoryProvider).getProfile();
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        _first.text = profile.firstName;
        _last.text = profile.lastName ?? '';
        _phone.text = profile.phone ?? '';
        _email.text = profile.email ?? '';
        _currency = profile.defaultCurrency;
      }
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editing && !_loaded) return const Scaffold(body: LoadingView());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing ? 'Editar perfil' : 'Tu perfil local'),
      ),
      body: AppPage(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
            children: [
              if (!widget.editing) ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Personaliza tu experiencia',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Esta información permanece únicamente en tu dispositivo.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                    ),
                  ),
                ],
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
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(
                  labelText: 'Moneda predeterminada',
                  prefixIcon: Icon(Icons.currency_exchange_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'DOP',
                    child: Text('DOP · Peso dominicano'),
                  ),
                  DropdownMenuItem(
                    value: 'USD',
                    child: Text('USD · Dólar estadounidense'),
                  ),
                  DropdownMenuItem(
                    value: 'EUR',
                    child: Text('EUR · Euro'),
                  ),
                ],
                onChanged: (value) => setState(() => _currency = value!),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  widget.editing ? 'Guardar cambios' : 'Comenzar',
                ),
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
      await ref.read(appRepositoryProvider).saveProfile(
            firstName: _first.text,
            lastName: _last.text,
            phone: _phone.text,
            email: _email.text,
            currency: _currency,
          );
      if (!mounted) return;
      showMessage(
        context,
        widget.editing ? 'Perfil actualizado' : 'Todo listo',
      );
      widget.editing ? context.pop() : context.go(RouteNames.home);
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
