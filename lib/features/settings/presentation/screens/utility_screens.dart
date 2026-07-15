import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/presentation/app_ui.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: AppPage(
          child: FutureBuilder<Map<String, Object?>>(
            future: ref.read(appRepositoryProvider).summary(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(message: '${snapshot.error}');
              }
              if (!snapshot.hasData) return const LoadingView();
              final data = snapshot.data!;
              final receivable = data['receivable']! as int;
              final payable = data['payable']! as int;
              final total = receivable + payable;
              final currency = data['currency']! as String;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Tu panorama',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Resumen calculado con tus datos locales.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          icon: Icons.south_west_rounded,
                          label: 'Por cobrar',
                          value: formatMinor(receivable, currency),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          icon: Icons.north_east_rounded,
                          label: 'Por pagar',
                          value: formatMinor(payable, currency),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Metric(
                    icon: Icons.balance_rounded,
                    label: 'Balance neto',
                    value: formatMinor(
                      (receivable - payable).abs(),
                      currency,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader('Distribución'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: total == 0 ? 0 : receivable / total,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${data['debts']} deudas'),
                              Text('${data['contacts']} contactos'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${data['activity']} movimientos registrados',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      );
}

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _path;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Respaldo local')),
        body: AppPage(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Tus datos, bajo tu control',
                message:
                    'Crea un archivo JSON con tu perfil, contactos, deudas y pagos. Puedes guardarlo o compartirlo usando las opciones del dispositivo.',
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _backup,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup_outlined),
                label: const Text('Crear respaldo'),
              ),
              if (_path != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir último respaldo'),
                ),
              ],
            ],
          ),
        ),
      );
  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      final json = await ref.read(appRepositoryProvider).exportJson();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        p.join(
          dir.path,
          'pagame_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        ),
      );
      await file.writeAsString(json, flush: true);
      setState(() => _path = file.path);
      if (mounted) showMessage(context, 'Respaldo creado correctamente');
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles([XFile(_path!)], subject: 'Respaldo de Págame');
  }
}

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});
  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  late Future<List<File>> _files = _loadFiles();
  Future<List<File>> _loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = await dir
        .list()
        .where(
          (entity) =>
              entity is File &&
              p.basename(entity.path).startsWith('pagame_backup_') &&
              entity.path.endsWith('.json'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Restaurar respaldo')),
        body: AppPage(
          child: FutureBuilder<List<File>>(
            future: _files,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(
                  message: '${snapshot.error}',
                  onRetry: () => setState(() => _files = _loadFiles()),
                );
              }
              if (!snapshot.hasData) return const LoadingView();
              final files = snapshot.data!;
              if (files.isEmpty) {
                return const EmptyState(
                  icon: Icons.restore_page_outlined,
                  title: 'No hay respaldos locales',
                  message:
                      'Crea un respaldo primero. Los archivos disponibles en este dispositivo aparecerán aquí.',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded),
                      title: Text(
                        'La restauración reemplaza los datos actuales',
                      ),
                      subtitle: Text(
                        'Elige un respaldo válido y confirma antes de continuar.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final file in files)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(p.basename(file.path)),
                          subtitle: Text(
                            '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                          ),
                          trailing: const Icon(Icons.restore_rounded),
                          onTap: () => _restore(file),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
  Future<void> _restore(File file) async {
    final confirmed = await confirmAction(
      context,
      title: 'Restaurar este respaldo',
      message:
          'Se reemplazarán el perfil, contactos, deudas y pagos actuales. Esta acción no se puede deshacer.',
      confirmLabel: 'Restaurar',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(appRepositoryProvider)
          .restoreJson(await file.readAsString());
      if (mounted) {
        showMessage(context, 'Respaldo restaurado');
        context.go('/home');
      }
    } catch (error) {
      if (mounted) showMessage(context, '$error', error: true);
    }
  }
}

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});
  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _loading = true;
  bool _enabled = false;
  bool _available = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = LocalAuthentication();
    final available = await auth.isDeviceSupported();
    final enabled =
        await ref.read(appRepositoryProvider).getSetting('biometricLock') ==
            'true';
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seguridad')),
        body: AppPage(
          child: _loading
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: SwitchListTile.adaptive(
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: const Text('Bloqueo biométrico'),
                        subtitle: Text(
                          _available
                              ? 'Solicita tu huella o rostro al activar la protección.'
                              : 'Este dispositivo no ofrece autenticación biométrica.',
                        ),
                        value: _enabled,
                        onChanged: _available ? _toggle : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.phonelink_lock_outlined),
                        title: Text('Almacenamiento local'),
                        subtitle: Text(
                          'La información permanece en este dispositivo y no se sincroniza con servidores.',
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
  Future<void> _toggle(bool value) async {
    if (value) {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: 'Confirma tu identidad para proteger Págame',
      );
      if (!ok) return;
    }
    await ref.read(appRepositoryProvider).setSetting('biometricLock', '$value');
    setState(() => _enabled = value);
    if (mounted) {
      showMessage(
        context,
        value ? 'Protección activada' : 'Protección desactivada',
      );
    }
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({
    required this.title,
    required this.body,
    this.icon = Icons.info_outline_rounded,
    super.key,
  });
  final String title;
  final String body;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AppPage(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                icon,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text(body, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: context.pop,
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
}
