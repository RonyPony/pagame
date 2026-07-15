import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(appRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Págame'),
            Text(
              'Las cuentas claras',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            onPressed: () => context.push(RouteNames.statistics),
            icon: const Icon(Icons.insights_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppPage(
        child: StreamBuilder<List<Debt>>(
          stream: repository.watchDebts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(message: '${snapshot.error}');
            }
            if (!snapshot.hasData) return const LoadingView();
            final debts = snapshot.data!;
            final currency = debts.isEmpty ? 'DOP' : debts.first.currencyCode;
            final currentCurrencyDebts =
                debts.where((debt) => debt.currencyCode == currency).toList();
            final receivable = currentCurrencyDebts
                .where((d) => d.direction == 'receivable')
                .fold<int>(
                  0,
                  (sum, d) => sum + d.outstandingAmountInMinorUnits,
                );
            final payable = currentCurrencyDebts
                .where((d) => d.direction == 'payable')
                .fold<int>(
                  0,
                  (sum, d) => sum + d.outstandingAmountInMinorUnits,
                );
            final recent = debts.take(4).toList();
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(appRepositoryProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  _BalanceCard(
                    receivable: receivable,
                    payable: payable,
                    currency: currency,
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Acciones rápidas'),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Presté',
                          onTap: () => context.push(
                            '${RouteNames.newDebt}?direction=receivable',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Me prestaron',
                          onTap: () => context
                              .push('${RouteNames.newDebt}?direction=payable'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.group_add_outlined,
                          label: 'Dividir',
                          onTap: () => context.push(RouteNames.newGroup),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    'Movimientos recientes',
                    action: recent.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () => context.go(RouteNames.debts),
                            child: const Text('Ver todos'),
                          ),
                  ),
                  if (recent.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Tus préstamos y pagos aparecerán aquí.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...recent.map(
                      (debt) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DebtPreview(debt: debt),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.receivable,
    required this.payable,
    required this.currency,
  });
  final int receivable;
  final int payable;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3D2E), Color(0xFF116247)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3D2E).withAlpha(45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance pendiente',
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            formatMinor((receivable - payable).abs(), currency),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  label: 'Me deben',
                  value: formatMinor(receivable, currency),
                  icon: Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withAlpha(45),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BalanceMetric(
                  label: 'Yo debo',
                  value: formatMinor(payable, currency),
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF62E3A3), size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DebtPreview extends StatelessWidget {
  const _DebtPreview({required this.debt});
  final Debt debt;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: () => context.push('/debts/${debt.id}'),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child:
                Text(debt.contactNameSnapshot.characters.first.toUpperCase()),
          ),
          title: Text(
            debt.contactNameSnapshot,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle:
              Text(debt.concept, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMinor(
                  debt.outstandingAmountInMinorUnits,
                  debt.currencyCode,
                ),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                debt.direction == 'receivable' ? 'Por cobrar' : 'Por pagar',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
}
