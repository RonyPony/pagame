import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({
    this.debtId,
    this.initialDirection,
    this.initialContactId,
    this.initialContactName,
    super.key,
  });
  final String? debtId;
  final String? initialDirection;
  final String? initialContactId;
  final String? initialContactName;
  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _concept = TextEditingController();
  final _description = TextEditingController();
  String _direction = 'receivable';
  String _currency = 'DOP';
  String? _contactId;
  DateTime _loanDate = DateTime.now();
  DateTime? _dueDate;
  bool _partial = true;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection ?? 'receivable';
    _contactId = widget.initialContactId;
    _name.text = widget.initialContactName ?? '';
    if (widget.debtId != null) _load();
  }

  Future<void> _load() async {
    final debt = await ref.read(appRepositoryProvider).getDebt(widget.debtId!);
    if (!mounted || debt == null) return;
    setState(() {
      _name.text = debt.contactNameSnapshot;
      _amount.text = (debt.amountInMinorUnits / 100).toStringAsFixed(2);
      _concept.text = debt.concept;
      _description.text = debt.description ?? '';
      _direction = debt.direction;
      _currency = debt.currencyCode;
      _contactId = debt.contactId;
      _loanDate = debt.loanDate.toLocal();
      _dueDate = debt.dueDate?.toLocal();
      _partial = debt.allowPartialPayments;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _concept.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debtId != null && !_loaded) {
      return const Scaffold(body: LoadingView());
    }
    final repository = ref.watch(appRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debtId == null ? 'Nueva deuda' : 'Editar deuda'),
      ),
      body: AppPage(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: [
              Text(
                '¿Quién debe a quién?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'receivable',
                    icon: Icon(Icons.south_west_rounded),
                    label: Text('Me deben'),
                  ),
                  ButtonSegment(
                    value: 'payable',
                    icon: Icon(Icons.north_east_rounded),
                    label: Text('Yo debo'),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (value) =>
                    setState(() => _direction = value.first),
              ),
              const SizedBox(height: 22),
              StreamBuilder<List<Contact>>(
                stream: repository.watchContacts(),
                builder: (context, snapshot) => Autocomplete<Contact>(
                  displayStringForOption: _contactName,
                  optionsBuilder: (value) {
                    final contacts = snapshot.data ?? const <Contact>[];
                    if (value.text.isEmpty) return contacts;
                    return contacts.where(
                      (c) => _contactName(c)
                          .toLowerCase()
                          .contains(value.text.toLowerCase()),
                    );
                  },
                  onSelected: (contact) {
                    _contactId = contact.id;
                    _name.text = _contactName(contact);
                  },
                  fieldViewBuilder: (context, controller, focus, onSubmit) {
                    if (controller.text.isEmpty && _name.text.isNotEmpty) {
                      controller.text = _name.text;
                    }
                    controller.addListener(() => _name.text = controller.text);
                    return TextFormField(
                      controller: controller,
                      focusNode: focus,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: _direction == 'receivable'
                            ? 'Persona que te debe'
                            : 'Persona a quien debes',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Escribe el nombre de la persona'
                              : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final amount = parseMoney(value ?? '');
                        return amount == null || amount <= 0
                            ? 'Ingresa un monto válido'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                      items: const ['DOP', 'USD', 'EUR']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _currency = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _concept,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  hintText: 'Ej. compra, préstamo, alquiler',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Describe brevemente el motivo'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Fecha',
                      value: _loanDate,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateTile(
                      label: 'Vence',
                      value: _dueDate,
                      onTap: () => _pickDate(true),
                      optional: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Permitir pagos parciales'),
                subtitle:
                    const Text('Registra abonos hasta completar el monto.'),
                value: _partial,
                onChanged: (value) => setState(() => _partial = value),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Guardando…' : 'Guardar deuda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _contactName(Contact contact) =>
      [contact.firstName, contact.lastName].whereType<String>().join(' ');

  Future<void> _pickDate(bool due) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: due
          ? (_dueDate ?? DateTime.now().add(const Duration(days: 7)))
          : _loanDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => due ? _dueDate = picked : _loanDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = await ref.read(appRepositoryProvider).saveDebt(
            id: widget.debtId,
            direction: _direction,
            contactName: _name.text,
            contactId: _contactId,
            amount: parseMoney(_amount.text)!,
            currency: _currency,
            concept: _concept.text,
            description: _description.text,
            loanDate: _loanDate,
            dueDate: _dueDate,
            allowPartialPayments: _partial,
          );
      if (!mounted) return;
      showMessage(
        context,
        widget.debtId == null ? 'Deuda registrada' : 'Cambios guardados',
      );
      context.go('/debts/$id');
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.optional = false,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool optional;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            value == null ? (optional ? 'Sin fecha' : '') : formatDate(value!),
          ),
        ),
      );
}

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({required this.debtId, super.key});
  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(appRepositoryProvider);
    return StreamBuilder<Debt?>(
      stream: repository.watchDebt(debtId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(message: '${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) return const Scaffold(body: LoadingView());
        final debt = snapshot.data;
        if (debt == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Deuda no encontrada',
              message: 'Es posible que haya sido eliminada.',
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(debt.publicCode),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') context.push('/debts/${debt.id}/edit');
                  if (value == 'archive' &&
                      await confirmAction(
                        context,
                        title: 'Archivar deuda',
                        message: 'La deuda dejará de aparecer en tus listas.',
                        confirmLabel: 'Archivar',
                      )) {
                    await repository.archiveDebt(debt);
                    if (context.mounted) context.go('/debts');
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(Icons.archive_outlined),
                      title: Text('Archivar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: AppPage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              children: [
                _DebtHero(debt: debt),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: debt.outstandingAmountInMinorUnits == 0
                            ? null
                            : () => context.push('/debts/${debt.id}/payment'),
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Registrar pago'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Crear recordatorio',
                      onPressed: () =>
                          context.push('/debts/${debt.id}/reminder'),
                      icon: const Icon(Icons.notifications_active_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader('Detalles'),
                Card(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Persona',
                        value: debt.contactNameSnapshot,
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: Icons.sell_outlined,
                        label: 'Concepto',
                        value: debt.concept,
                      ),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Fecha',
                        value: formatDate(debt.loanDate),
                      ),
                      if (debt.dueDate != null) ...[
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.event_outlined,
                          label: 'Vencimiento',
                          value: formatDate(debt.dueDate!),
                        ),
                      ],
                      if (debt.description != null) ...[
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.notes_rounded,
                          label: 'Descripción',
                          value: debt.description!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader('Pagos'),
                StreamBuilder<List<Payment>>(
                  stream: repository.watchPayments(debt.id),
                  builder: (context, paymentSnapshot) {
                    if (!paymentSnapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final payments = paymentSnapshot.data!;
                    if (payments.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('Aún no se han registrado pagos.'),
                        ),
                      );
                    }
                    return Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < payments.length; i++) ...[
                            ListTile(
                              leading: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                              title: Text(
                                formatMinor(
                                  payments[i].amountInMinorUnits,
                                  payments[i].currencyCode,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${formatDate(payments[i].paymentDate)} · ${_paymentMethod(payments[i].paymentMethod)}',
                              ),
                            ),
                            if (i != payments.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const SectionHeader('Recordatorios'),
                StreamBuilder<List<Reminder>>(
                  stream: repository.watchReminders(debt.id),
                  builder: (context, reminderSnapshot) {
                    if (!reminderSnapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final reminders = reminderSnapshot.data!;
                    if (reminders.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('No hay recordatorios programados.'),
                        ),
                      );
                    }
                    return Card(
                      child: Column(
                        children: reminders
                            .map(
                              (r) => ListTile(
                                leading: const Icon(
                                  Icons.notifications_outlined,
                                ),
                                title: Text(r.title),
                                subtitle: Text(
                                  '${formatDate(r.scheduledAt)} · ${r.status == 'scheduled' ? 'Programado' : r.status}',
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
  }
}

class _DebtHero extends StatelessWidget {
  const _DebtHero({required this.debt});
  final Debt debt;
  @override
  Widget build(BuildContext context) {
    final progress = debt.amountInMinorUnits == 0
        ? 0.0
        : debt.paidAmountInMinorUnits / debt.amountInMinorUnits;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            debt.direction == 'receivable'
                ? 'Saldo por cobrar'
                : 'Saldo por pagar',
            style: TextStyle(color: Colors.white.withAlpha(190)),
          ),
          const SizedBox(height: 5),
          Text(
            formatMinor(debt.outstandingAmountInMinorUnits, debt.currencyCode),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withAlpha(35),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF66E4A5)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% pagado',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                'Total ${formatMinor(debt.amountInMinorUnits, debt.currencyCode)}',
                style:
                    TextStyle(color: Colors.white.withAlpha(190), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle:
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({required this.debtId, super.key});
  final String debtId;
  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  String _method = 'cash';
  DateTime _date = DateTime.now();
  bool _saving = false;
  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Debt?>(
        future: ref.read(appRepositoryProvider).getDebt(widget.debtId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: LoadingView());
          final debt = snapshot.data!;
          return Scaffold(
            appBar: AppBar(title: const Text('Registrar pago')),
            body: AppPage(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          debt.contactNameSnapshot,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Saldo ${formatMinor(debt.outstandingAmountInMinorUnits, debt.currencyCode)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Monto del pago (${debt.currencyCode})',
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final amount = parseMoney(value ?? '');
                        return amount == null ||
                                amount <= 0 ||
                                amount > debt.outstandingAmountInMinorUnits
                            ? 'Ingresa un monto entre 0 y el saldo pendiente'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(
                        labelText: 'Método de pago',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Text('Transferencia'),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Tarjeta'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: (value) => _method = value!,
                    ),
                    const SizedBox(height: 14),
                    _DateTile(
                      label: 'Fecha del pago',
                      value: _date,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _reference,
                      decoration: const InputDecoration(
                        labelText: 'Referencia (opcional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _note,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(debt),
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Confirmar pago'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _save(Debt debt) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(appRepositoryProvider).addPayment(
            debt: debt,
            amount: parseMoney(_amount.text)!,
            date: _date,
            method: _method,
            reference: _reference.text,
            note: _note.text,
          );
      if (mounted) {
        showMessage(context, 'Pago registrado correctamente');
        context.pop();
      }
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ReminderFormScreen extends ConsumerStatefulWidget {
  const ReminderFormScreen({required this.debtId, super.key});
  final String debtId;
  @override
  ConsumerState<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Recordatorio de pago');
  final _body = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Debt?>(
        future: ref.read(appRepositoryProvider).getDebt(widget.debtId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: LoadingView());
          final debt = snapshot.data!;
          if (_body.text.isEmpty) {
            _body.text =
                '${debt.contactNameSnapshot}, recuerda el pago pendiente de ${formatMinor(debt.outstandingAmountInMinorUnits, debt.currencyCode)}.';
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Crear recordatorio')),
            body: AppPage(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe un título'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _body,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Mensaje',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe el mensaje'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DateTile(
                            label: 'Fecha',
                            value: _date,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _pickTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Hora',
                                prefixIcon: Icon(Icons.schedule_outlined),
                              ),
                              child: Text(_time.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(debt),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Programar recordatorio'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'El recordatorio queda guardado localmente en esta deuda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);
    if (result != null) setState(() => _time = result);
  }

  Future<void> _save(Debt debt) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final scheduled =
        DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    try {
      await ref.read(appRepositoryProvider).addReminder(
            debt: debt,
            scheduledAt: scheduled,
            title: _title.text,
            body: _body.text,
          );
      if (mounted) {
        showMessage(context, 'Recordatorio guardado');
        context.pop();
      }
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _paymentMethod(String method) => switch (method) {
      'cash' => 'Efectivo',
      'transfer' => 'Transferencia',
      'card' => 'Tarjeta',
      _ => 'Otro'
    };
