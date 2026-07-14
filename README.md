# Págame

**Las cuentas claras conservan la amistad.**

Págame es una aplicación móvil Flutter para registrar préstamos, deudas, pagos, cuotas y recordatorios de forma completamente local. No usa backend, Firebase, APIs remotas, autenticación remota ni sincronización automática. La persistencia principal es SQLite mediante Drift.

## Estado de esta entrega incremental

Esta primera fase establece la base del proyecto:

- Estructura Flutter feature-first.
- Dependencias obligatorias principales.
- Tema Material Design 3 claro/oscuro.
- Navegación declarativa con GoRouter.
- ARB para `es_DO` y `en_US`.
- Base de datos Drift con tablas MVP y datos iniciales.
- Value Object `Money` con operaciones seguras por moneda.
- Servicio de dominio para resolver estados de deuda.
- Onboarding inicial de tres pantallas.
- Pantalla de perfil local inicial.
- Pantallas base de dashboard, deudas, contactos, actividad y perfil.

## Privacidad y funcionamiento local

- Los datos permanecen en el dispositivo.
- Págame no transmite información a servidores.
- Desinstalar la aplicación puede eliminar los datos.
- El usuario debe crear respaldos manuales.
- Compartir archivos o mensajes depende de la decisión del usuario.
- Los permisos son opcionales y contextuales.

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
flutter test
flutter build apk
flutter build appbundle
flutter build ios
```

## Generación de código

Drift requiere generar `app_database.g.dart` antes de compilar:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Restricciones técnicas

No agregar backend, Firebase, Supabase, Appwrite, APIs remotas, tokens JWT, cuentas remotas ni dependencias obligatorias de internet.
