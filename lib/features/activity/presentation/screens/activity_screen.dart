import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Actividad')),
        body: AppPage(
          child: StreamBuilder<List<ActivityEvent>>(
            stream: ref.watch(appRepositoryProvider).watchActivity(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(message: '${snapshot.error}');
              }
              if (!snapshot.hasData) return const LoadingView();
              final events = snapshot.data!;
              if (events.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Sin actividad todavía',
                  message:
                      'Los cambios en deudas, pagos, contactos y grupos se guardarán aquí.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final icon = switch (event.eventType) {
                    'payment_created' => Icons.payments_outlined,
                    'contact_created' ||
                    'contact_updated' =>
                      Icons.person_outline_rounded,
                    'reminder_created' => Icons.notifications_outlined,
                    'group_created' ||
                    'participant_created' =>
                      Icons.groups_outlined,
                    _ => Icons.receipt_long_outlined
                  };
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (index != events.length - 1)
                            Container(
                              width: 2,
                              height: 54,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                        ],
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatDate(event.createdAt),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
}
