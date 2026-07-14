import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/debts/presentation/screens/debts_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/setup_profile_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.onboarding,
  routes: [
    GoRoute(path: RouteNames.root, redirect: (_, __) => RouteNames.home),
    GoRoute(path: RouteNames.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: RouteNames.setupProfile, builder: (_, __) => const SetupProfileScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainScaffold(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: RouteNames.home, builder: (_, __) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: RouteNames.debts, builder: (_, __) => const DebtsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: RouteNames.contacts, builder: (_, __) => const ContactsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: RouteNames.activity, builder: (_, __) => const ActivityScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfileScreen())]),
      ],
    ),
    for (final path in [RouteNames.newDebt, RouteNames.groups, RouteNames.statistics, RouteNames.backup, RouteNames.restore, RouteNames.security, RouteNames.help, RouteNames.terms, RouteNames.privacy, RouteNames.settings])
      GoRoute(path: path, builder: (_, state) => PlaceholderScreen(title: path)),
    GoRoute(path: '/debts/:id', builder: (_, state) => PlaceholderScreen(title: 'Deuda ${state.pathParameters['id']}')),
    GoRoute(path: '/debts/:id/edit', builder: (_, __) => const PlaceholderScreen(title: 'Editar deuda')),
    GoRoute(path: '/debts/:id/payment', builder: (_, __) => const PlaceholderScreen(title: 'Registrar pago')),
    GoRoute(path: '/debts/:id/reminder', builder: (_, __) => const PlaceholderScreen(title: 'Recordatorio')),
    GoRoute(path: '/contacts/new', builder: (_, __) => const PlaceholderScreen(title: 'Nuevo contacto')),
    GoRoute(path: '/contacts/:id', builder: (_, __) => const PlaceholderScreen(title: 'Contacto')),
    GoRoute(path: '/groups/new', builder: (_, __) => const PlaceholderScreen(title: 'Nuevo grupo')),
    GoRoute(path: '/groups/:id', builder: (_, __) => const PlaceholderScreen(title: 'Grupo')),
  ],
);

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: shell.goBranch,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Deudas'),
        NavigationDestination(icon: Icon(Icons.add_circle), label: 'Crear'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Actividad'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
      ],
    ),
  );
}

class PlaceholderScreen extends StatelessWidget { const PlaceholderScreen({required this.title, super.key}); final String title; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(title))); }
