import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});
  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  String _filter = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(appRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        actions: [
          IconButton(
            tooltip: 'Nueva deuda',
            onPressed: () => context.push(RouteNames.newDebt),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debtFab',
        onPressed: () => context.push(RouteNames.newDebt),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva'),
      ),
      body: AppPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar persona o concepto',
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('all', 'Todas'),
                  _chip('receivable', 'Me deben'),
                  _chip('payable', 'Yo debo'),
                  _chip('overdue', 'Vencidas'),
                  _chip('paid', 'Pagadas'),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Debt>>(
                stream: repository.watchDebts(
                  direction: {'receivable', 'payable'}.contains(_filter)
                      ? _filter
                      : null,
                  status:
                      {'overdue', 'paid'}.contains(_filter) ? _filter : null,
                  query: _query,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorState(message: '${snapshot.error}');
                  }
                  if (!snapshot.hasData) return const LoadingView();
                  final debts = snapshot.data!;
                  if (debts.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: _query.isEmpty
                          ? 'Aún no hay deudas'
                          : 'Sin resultados',
                      message: _query.isEmpty
                          ? 'Registra lo que prestaste o lo que debes y mantén cada pago bajo control.'
                          : 'Prueba con otro nombre, concepto o filtro.',
                      actionLabel: _query.isEmpty ? 'Registrar deuda' : null,
                      onAction: _query.isEmpty
                          ? () => context.push(RouteNames.newDebt)
                          : null,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: debts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        DebtCard(debt: debts[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == value,
          onSelected: (_) => setState(() => _filter = value),
        ),
      );
}

class DebtCard extends StatelessWidget {
  const DebtCard({required this.debt, super.key});
  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final overdue = debt.status == 'overdue';
    final paid = debt.status == 'paid';
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/debts/${debt.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    overdue ? scheme.errorContainer : scheme.primaryContainer,
                foregroundColor: overdue
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
                child: Text(
                  debt.contactNameSnapshot.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            debt.contactNameSnapshot,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _StatusBadge(status: debt.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      debt.concept,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          debt.direction == 'receivable'
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          debt.direction == 'receivable'
                              ? 'Por cobrar'
                              : 'Por pagar',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (debt.dueDate != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today_outlined, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(debt.dueDate!),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMinor(
                      debt.outstandingAmountInMinorUnits,
                      debt.currencyCode,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    paid ? 'Completada' : 'pendiente',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'overdue' => ('Vencida', scheme.error),
      'paid' => ('Pagada', const Color(0xFF208454)),
      'partiallyPaid' => ('Parcial', const Color(0xFFB56A00)),
      _ => ('Activa', scheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
