import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database_provider.dart';
import '../../core/presentation/app_ui.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/debts/presentation/screens/debt_flow_screens.dart';
import '../../features/debts/presentation/screens/debts_screen.dart';
import '../../features/groups/presentation/screens/groups_screens.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/setup_profile_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/utility_screens.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.root,
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Página no encontrada')),
    body: ErrorState(
      message: state.error?.toString() ?? 'La ruta solicitada no existe.',
      onRetry: () => context.go(RouteNames.home),
    ),
  ),
  routes: [
    GoRoute(path: RouteNames.root, builder: (_, __) => const AppGateScreen()),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RouteNames.setupProfile,
      builder: (_, __) => const SetupProfileScreen(),
    ),
    GoRoute(
      path: RouteNames.editProfile,
      builder: (_, __) => const SetupProfileScreen(editing: true),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.home,
              builder: (_, __) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.debts,
              builder: (_, __) => const DebtsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.contacts,
              builder: (_, __) => const ContactsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.activity,
              builder: (_, __) => const ActivityScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.newDebt,
      builder: (_, state) => DebtFormScreen(
        initialDirection: state.uri.queryParameters['direction'],
        initialContactId: state.uri.queryParameters['contactId'],
        initialContactName: state.uri.queryParameters['contactName'],
      ),
    ),
    GoRoute(
      path: '/debts/:id',
      builder: (_, state) =>
          DebtDetailScreen(debtId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/debts/:id/edit',
      builder: (_, state) =>
          DebtFormScreen(debtId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/debts/:id/payment',
      builder: (_, state) =>
          PaymentFormScreen(debtId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/debts/:id/reminder',
      builder: (_, state) =>
          ReminderFormScreen(debtId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/contacts/new',
      builder: (_, __) => const ContactFormScreen(),
    ),
    GoRoute(
      path: '/contacts/:id',
      builder: (_, state) =>
          ContactDetailScreen(contactId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/contacts/:id/edit',
      builder: (_, state) =>
          ContactFormScreen(contactId: state.pathParameters['id']!),
    ),
    GoRoute(path: RouteNames.groups, builder: (_, __) => const GroupsScreen()),
    GoRoute(
      path: RouteNames.newGroup,
      builder: (_, __) => const GroupFormScreen(),
    ),
    GoRoute(
      path: '/groups/:id',
      builder: (_, state) =>
          GroupDetailScreen(groupId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: RouteNames.statistics,
      builder: (_, __) => const StatisticsScreen(),
    ),
    GoRoute(path: RouteNames.backup, builder: (_, __) => const BackupScreen()),
    GoRoute(
      path: RouteNames.restore,
      builder: (_, __) => const RestoreScreen(),
    ),
    GoRoute(
      path: RouteNames.security,
      builder: (_, __) => const SecurityScreen(),
    ),
    GoRoute(path: RouteNames.settings, redirect: (_, __) => RouteNames.profile),
    GoRoute(
      path: RouteNames.help,
      builder: (_, __) => const InfoScreen(
        title: 'Ayuda',
        icon: Icons.help_outline_rounded,
        body:
            'Págame organiza préstamos, deudas y pagos de forma local.\n\nPara comenzar, crea un contacto o registra una deuda desde Inicio. Cada abono actualiza el saldo automáticamente. Puedes programar recordatorios dentro del detalle de una deuda, dividir gastos en Grupos y crear respaldos desde tu Perfil.\n\nTus datos no salen del dispositivo salvo cuando decides compartir un respaldo.',
      ),
    ),
    GoRoute(
      path: RouteNames.privacy,
      builder: (_, __) => const InfoScreen(
        title: 'Privacidad',
        icon: Icons.shield_outlined,
        body:
            'Págame funciona sin cuentas remotas ni sincronización automática. Tu perfil, contactos, deudas, pagos y ajustes se almacenan localmente en el dispositivo.\n\nLa aplicación solo solicita permisos cuando una función lo necesita. Los respaldos se crean bajo tu control y únicamente se comparten cuando eliges hacerlo. Desinstalar la aplicación puede eliminar los datos locales.',
      ),
    ),
    GoRoute(
      path: RouteNames.terms,
      builder: (_, __) => const InfoScreen(
        title: 'Términos de uso',
        icon: Icons.description_outlined,
        body:
            'Págame es una herramienta personal de registro y organización. Los datos introducidos son responsabilidad del usuario y no constituyen contratos, servicios bancarios ni asesoría financiera.\n\nMantén respaldos actualizados y verifica los montos antes de registrar pagos. El uso de la aplicación implica aceptar su funcionamiento local y sin sincronización automática.',
      ),
    ),
  ],
);

class AppGateScreen extends ConsumerStatefulWidget {
  const AppGateScreen({super.key});
  @override
  ConsumerState<AppGateScreen> createState() => _AppGateScreenState();
}

class _AppGateScreenState extends ConsumerState<AppGateScreen> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final profile = await ref.read(appRepositoryProvider).getProfile();
      if (!mounted) return;
      context.go(profile == null ? RouteNames.onboarding : RouteNames.home);
    } catch (_) {
      if (mounted) context.go(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: LoadingView());
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Deudas',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Contactos',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_toggle_off_rounded),
              label: 'Actividad',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      );
}
