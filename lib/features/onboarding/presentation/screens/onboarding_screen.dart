import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';

class OnboardingScreen extends StatefulWidget { const OnboardingScreen({super.key}); @override State<OnboardingScreen> createState() => _OnboardingScreenState(); }
class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController(); int page = 0;
  static const slides = [
    ('Registra lo que prestas', 'Guarda cada préstamo con monto, fecha y motivo.', Icons.savings_outlined),
    ('Controla cada pago', 'Registra pagos completos, parciales y cuotas pendientes.', Icons.payments_outlined),
    ('Cobra sin perseguir', 'Programa recordatorios y compártelos cuando llegue el momento.', Icons.notifications_active_outlined),
  ];
  void finish() => context.go(RouteNames.setupProfile);
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Column(children: [
      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: finish, child: const Text('Omitir'))),
      Expanded(child: PageView.builder(controller: controller, itemCount: slides.length, onPageChanged: (v) => setState(() => page = v), itemBuilder: (_, i) { final s = slides[i]; return Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(s.$3, size: 96), const SizedBox(height: 24), Text(s.$1, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center), const SizedBox(height: 12), Text(s.$2, textAlign: TextAlign.center), const SizedBox(height: 24), Text('Las cuentas claras conservan la amistad.', style: Theme.of(context).textTheme.titleMedium)])); })),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < slides.length; i++) Padding(padding: const EdgeInsets.all(4), child: CircleAvatar(radius: 4, backgroundColor: i == page ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor))]),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: OutlinedButton(onPressed: page == 0 ? null : () => controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut), child: const Text('Atrás'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: page == slides.length - 1 ? finish : () => controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut), child: const Text('Continuar')))])),
    ])),
  );
}
