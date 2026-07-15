import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagame/core/database/app_database.dart';
import 'package:pagame/core/database/app_repository.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase database;
  late AppRepository repository;

  setUpAll(() {
    open.overrideFor(
      OperatingSystem.linux,
      () =>
          DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0.8.6'),
    );
  });

  setUp(() {
    database = AppDatabase.forExecutor(NativeDatabase.memory());
    repository = AppRepository(database);
  });

  tearDown(() => database.close());

  test('guarda perfil, contacto, deuda y pago de principio a fin', () async {
    await repository.saveProfile(firstName: 'Ana', currency: 'DOP');
    final profile = await repository.getProfile();
    expect(profile?.firstName, 'Ana');

    final contactId = await repository.saveContact(
      firstName: 'Luis',
      phone: '8095550101',
    );
    final debtId = await repository.saveDebt(
      direction: 'receivable',
      contactId: contactId,
      contactName: 'Luis',
      amount: 100000,
      currency: 'DOP',
      concept: 'Préstamo',
      loanDate: DateTime(2026, 7, 15),
    );
    final debt = await repository.getDebt(debtId);
    expect(debt?.outstandingAmountInMinorUnits, 100000);

    await repository.addPayment(
      debt: debt!,
      amount: 25000,
      date: DateTime(2026, 7, 16),
      method: 'cash',
    );
    final updated = await repository.getDebt(debtId);
    expect(updated?.paidAmountInMinorUnits, 25000);
    expect(updated?.outstandingAmountInMinorUnits, 75000);
    expect(updated?.status, 'partiallyPaid');
  });

  test('exporta y restaura un respaldo compatible', () async {
    await repository.saveProfile(firstName: 'María', currency: 'USD');
    await repository.saveContact(firstName: 'Carlos');
    final backup = await repository.exportJson();

    await repository.saveProfile(firstName: 'Cambiado', currency: 'DOP');
    await repository.restoreJson(backup);

    expect((await repository.getProfile())?.firstName, 'María');
    expect(
      await repository.watchContacts().first.then((value) => value.length),
      1,
    );
  });
}
