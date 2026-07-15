import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppProfiles,
    Contacts,
    Debts,
    Payments,
    Installments,
    Reminders,
    DebtAttachments,
    PaymentAttachments,
    Groups,
    GroupParticipants,
    ActivityEvents,
    Categories,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forExecutor(super.executor);

  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await _createIndexes();
        },
      );

  Future<void> _seedDefaults() async {
    final now = DateTime.now().toUtc();
    final names = [
      'Préstamo',
      'Comida',
      'Transporte',
      'Compra',
      'Servicio',
      'Alquiler',
      'Emergencia',
      'Trabajo',
      'Viaje',
      'Otro',
    ];
    await batch(
      (b) => b.insertAll(categories, [
        for (var i = 0; i < names.length; i++)
          CategoriesCompanion.insert(
            id: 'cat_${i + 1}',
            name: names[i],
            localeKey: 'category_${i + 1}',
            sortOrder: i,
            createdAt: now,
          ),
      ]),
    );
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: 'locale',
        value: 'es_DO',
        updatedAt: now,
      ),
    );
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        key: 'defaultCurrency',
        value: 'DOP',
        updatedAt: now,
      ),
    );
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_contact_id ON debts(contact_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_due_date ON debts(due_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_currency ON debts(currency_code)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_debts_created_at ON debts(created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_debt_id ON payments(debt_id)',
    );
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'pagame.sqlite')),
      );
    });
