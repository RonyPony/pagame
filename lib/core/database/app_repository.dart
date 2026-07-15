import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

class AppRepository {
  AppRepository(this.db);

  final AppDatabase db;
  static const _uuid = Uuid();

  Stream<AppProfile?> watchProfile() =>
      (db.select(db.appProfiles)..limit(1)).watchSingleOrNull();

  Future<AppProfile?> getProfile() =>
      (db.select(db.appProfiles)..limit(1)).getSingleOrNull();

  Future<void> saveProfile({
    required String firstName,
    required String currency,
    String? lastName,
    String? phone,
    String? email,
  }) async {
    final existing = await getProfile();
    final now = DateTime.now().toUtc();
    final id = existing?.id ?? _uuid.v4();
    await db.into(db.appProfiles).insertOnConflictUpdate(
          AppProfilesCompanion.insert(
            id: id,
            firstName: firstName.trim(),
            lastName: Value(_clean(lastName)),
            phone: Value(_clean(phone)),
            email: Value(_clean(email)),
            defaultCurrency: Value(currency),
            countryCode: const Value('DO'),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    await setSetting('defaultCurrency', currency);
    await _activity('profile_updated', 'profile', id, 'Perfil actualizado');
  }

  Stream<List<Contact>> watchContacts({String query = ''}) {
    final statement = db.select(db.contacts)
      ..where((row) => row.archivedAt.isNull())
      ..orderBy([(row) => OrderingTerm.asc(row.firstName)]);
    if (query.trim().isNotEmpty) {
      final pattern = '%${query.trim()}%';
      statement.where(
        (row) =>
            row.firstName.like(pattern) |
            row.lastName.like(pattern) |
            row.alias.like(pattern) |
            row.phone.like(pattern),
      );
    }
    return statement.watch();
  }

  Future<Contact?> getContact(String id) =>
      (db.select(db.contacts)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Future<String> saveContact({
    String? id,
    required String firstName,
    String? lastName,
    String? alias,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final existing = id == null ? null : await getContact(id);
    final now = DateTime.now().toUtc();
    final contactId = id ?? _uuid.v4();
    await db.into(db.contacts).insertOnConflictUpdate(
          ContactsCompanion.insert(
            id: contactId,
            firstName: firstName.trim(),
            lastName: Value(_clean(lastName)),
            alias: Value(_clean(alias)),
            phone: Value(_clean(phone)),
            email: Value(_clean(email)),
            notes: Value(_clean(notes)),
            source: const Value('manual'),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    await _activity(
      existing == null ? 'contact_created' : 'contact_updated',
      'contact',
      contactId,
      existing == null
          ? 'Contacto ${firstName.trim()} creado'
          : 'Contacto ${firstName.trim()} actualizado',
    );
    return contactId;
  }

  Future<void> archiveContact(Contact contact) async {
    await (db.update(db.contacts)..where((row) => row.id.equals(contact.id)))
        .write(
      ContactsCompanion(archivedAt: Value(DateTime.now().toUtc())),
    );
    await _activity(
      'contact_archived',
      'contact',
      contact.id,
      'Contacto ${contact.firstName} archivado',
    );
  }

  Stream<List<Debt>> watchDebts({
    String? direction,
    String? status,
    String query = '',
  }) {
    final statement = db.select(db.debts)
      ..where((row) => row.archivedAt.isNull())
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    if (direction != null) {
      statement.where((row) => row.direction.equals(direction));
    }
    if (status != null) statement.where((row) => row.status.equals(status));
    if (query.trim().isNotEmpty) {
      final pattern = '%${query.trim()}%';
      statement.where(
        (row) =>
            row.contactNameSnapshot.like(pattern) | row.concept.like(pattern),
      );
    }
    return statement.watch();
  }

  Future<Debt?> getDebt(String id) =>
      (db.select(db.debts)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Stream<Debt?> watchDebt(String id) =>
      (db.select(db.debts)..where((row) => row.id.equals(id)))
          .watchSingleOrNull();

  Stream<List<Payment>> watchPayments(String debtId) => (db.select(db.payments)
        ..where((row) => row.debtId.equals(debtId))
        ..orderBy([(row) => OrderingTerm.desc(row.paymentDate)]))
      .watch();

  Stream<List<Reminder>> watchReminders(String debtId) =>
      (db.select(db.reminders)
            ..where((row) => row.debtId.equals(debtId))
            ..orderBy([(row) => OrderingTerm.asc(row.scheduledAt)]))
          .watch();

  Future<String> saveDebt({
    String? id,
    required String direction,
    required String contactName,
    required int amount,
    required String currency,
    required String concept,
    required DateTime loanDate,
    String? contactId,
    String? contactPhone,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    String? privateNote,
    bool allowPartialPayments = true,
  }) async {
    final existing = id == null ? null : await getDebt(id);
    final now = DateTime.now().toUtc();
    final debtId = id ?? _uuid.v4();
    final paid = existing?.paidAmountInMinorUnits ?? 0;
    final outstanding = amount - paid;
    if (outstanding < 0) {
      throw ArgumentError('El monto no puede ser menor que lo ya pagado.');
    }
    final status = _resolveStatus(outstanding, paid, dueDate, now);
    await db.into(db.debts).insertOnConflictUpdate(
          DebtsCompanion.insert(
            id: debtId,
            publicCode: existing?.publicCode ?? _publicCode(),
            direction: direction,
            contactId: Value(contactId),
            contactNameSnapshot: contactName.trim(),
            contactPhoneSnapshot: Value(_clean(contactPhone)),
            amountInMinorUnits: amount,
            paidAmountInMinorUnits: Value(paid),
            outstandingAmountInMinorUnits: outstanding,
            currencyCode: currency,
            concept: concept.trim(),
            description: Value(_clean(description)),
            categoryId: Value(categoryId),
            loanDate: loanDate.toUtc(),
            dueDate: Value(dueDate?.toUtc()),
            status: status,
            agreementStatus: existing?.agreementStatus ?? 'notSpecified',
            allowPartialPayments: Value(allowPartialPayments),
            privateNote: Value(_clean(privateNote)),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            completedAt: Value(outstanding == 0 ? now : null),
          ),
        );
    await _activity(
      existing == null ? 'debt_created' : 'debt_updated',
      'debt',
      debtId,
      existing == null
          ? 'Deuda con ${contactName.trim()} creada'
          : 'Deuda con ${contactName.trim()} actualizada',
    );
    return debtId;
  }

  Future<void> archiveDebt(Debt debt) async {
    await (db.update(db.debts)..where((row) => row.id.equals(debt.id))).write(
      DebtsCompanion(
        status: const Value('archived'),
        archivedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _activity(
      'debt_archived',
      'debt',
      debt.id,
      'Deuda ${debt.publicCode} archivada',
    );
  }

  Future<void> addPayment({
    required Debt debt,
    required int amount,
    required DateTime date,
    required String method,
    String? reference,
    String? note,
  }) async {
    if (amount <= 0 || amount > debt.outstandingAmountInMinorUnits) {
      throw ArgumentError(
        'El pago debe ser mayor que cero y no superar el saldo.',
      );
    }
    final now = DateTime.now().toUtc();
    final paid = debt.paidAmountInMinorUnits + amount;
    final outstanding = debt.amountInMinorUnits - paid;
    await db.transaction(() async {
      final id = _uuid.v4();
      await db.into(db.payments).insert(
            PaymentsCompanion.insert(
              id: id,
              debtId: debt.id,
              amountInMinorUnits: amount,
              currencyCode: debt.currencyCode,
              paymentDate: date.toUtc(),
              paymentMethod: method,
              reference: Value(_clean(reference)),
              note: Value(_clean(note)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await (db.update(db.debts)..where((row) => row.id.equals(debt.id))).write(
        DebtsCompanion(
          paidAmountInMinorUnits: Value(paid),
          outstandingAmountInMinorUnits: Value(outstanding),
          status: Value(outstanding == 0 ? 'paid' : 'partiallyPaid'),
          completedAt: Value(outstanding == 0 ? now : null),
          updatedAt: Value(now),
        ),
      );
      await _activity(
        'payment_created',
        'debt',
        debt.id,
        'Pago registrado en ${debt.publicCode}',
      );
    });
  }

  Future<void> addReminder({
    required Debt debt,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await db.into(db.reminders).insert(
          RemindersCompanion.insert(
            id: id,
            debtId: debt.id,
            title: title.trim(),
            body: body.trim(),
            scheduledAt: scheduledAt.toUtc(),
            status: 'scheduled',
            platformNotificationId: id.hashCode.abs() % 2147483647,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _activity(
      'reminder_created',
      'debt',
      debt.id,
      'Recordatorio creado para ${debt.publicCode}',
    );
  }

  Stream<List<ActivityEvent>> watchActivity() => (db.select(db.activityEvents)
        ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
      .watch();

  Stream<List<Category>> watchCategories() => (db.select(db.categories)
        ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
      .watch();

  Stream<List<Group>> watchGroups() => (db.select(db.groups)
        ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
      .watch();

  Future<Group?> getGroup(String id) =>
      (db.select(db.groups)..where((row) => row.id.equals(id)))
          .getSingleOrNull();

  Stream<List<GroupParticipant>> watchGroupParticipants(String groupId) =>
      (db.select(db.groupParticipants)
            ..where((row) => row.groupId.equals(groupId)))
          .watch();

  Future<String> createGroup({
    required String name,
    required String currency,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await db.into(db.groups).insert(
          GroupsCompanion.insert(
            id: id,
            name: name.trim(),
            description: Value(_clean(description)),
            currencyCode: currency,
            totalAmountInMinorUnits: 0,
            createdAt: now,
            updatedAt: now,
            status: 'active',
          ),
        );
    await _activity(
      'group_created',
      'group',
      id,
      'Grupo ${name.trim()} creado',
    );
    return id;
  }

  Future<void> addGroupParticipant({
    required Group group,
    required String name,
    required int amount,
    String? contactId,
  }) async {
    final id = _uuid.v4();
    await db.transaction(() async {
      await db.into(db.groupParticipants).insert(
            GroupParticipantsCompanion.insert(
              id: id,
              groupId: group.id,
              contactId: Value(contactId),
              contactNameSnapshot: name.trim(),
              assignedAmountInMinorUnits: amount,
              outstandingAmountInMinorUnits: amount,
              status: 'pending',
            ),
          );
      await (db.update(db.groups)..where((row) => row.id.equals(group.id)))
          .write(
        GroupsCompanion(
          totalAmountInMinorUnits:
              Value(group.totalAmountInMinorUnits + amount),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      await _activity(
        'participant_created',
        'group',
        group.id,
        '${name.trim()} agregado a ${group.name}',
      );
    });
  }

  Future<String?> getSetting(String key) async =>
      (await (db.select(db.appSettings)..where((row) => row.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  Future<void> setSetting(String key, String value) =>
      db.into(db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now().toUtc(),
            ),
          );

  Future<Map<String, Object?>> summary() async {
    final debts = await (db.select(db.debts)
          ..where((row) => row.archivedAt.isNull()))
        .get();
    final contacts = await (db.select(db.contacts)
          ..where((row) => row.archivedAt.isNull()))
        .get();
    final activity = await db.select(db.activityEvents).get();
    final currency = (await getProfile())?.defaultCurrency ?? 'DOP';
    final selectedDebts = debts.where(
      (debt) => debt.currencyCode == currency,
    );
    return {
      'debts': debts.length,
      'contacts': contacts.length,
      'activity': activity.length,
      'currency': currency,
      'receivable': selectedDebts
          .where((d) => d.direction == 'receivable')
          .fold<int>(0, (sum, d) => sum + d.outstandingAmountInMinorUnits),
      'payable': selectedDebts
          .where((d) => d.direction == 'payable')
          .fold<int>(0, (sum, d) => sum + d.outstandingAmountInMinorUnits),
    };
  }

  Future<String> exportJson() async {
    final profile = await getProfile();
    final contacts = await db.select(db.contacts).get();
    final debts = await db.select(db.debts).get();
    final payments = await db.select(db.payments).get();
    final installments = await db.select(db.installments).get();
    final reminders = await db.select(db.reminders).get();
    final debtAttachments = await db.select(db.debtAttachments).get();
    final paymentAttachments = await db.select(db.paymentAttachments).get();
    final groups = await db.select(db.groups).get();
    final participants = await db.select(db.groupParticipants).get();
    final settings = await db.select(db.appSettings).get();
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'profile': profile?.toJson(),
      'contacts': contacts.map((e) => e.toJson()).toList(),
      'debts': debts.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
      'installments': installments.map((e) => e.toJson()).toList(),
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'debtAttachments': debtAttachments.map((e) => e.toJson()).toList(),
      'paymentAttachments': paymentAttachments.map((e) => e.toJson()).toList(),
      'groups': groups.map((e) => e.toJson()).toList(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'settings': settings.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> restoreJson(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      throw const FormatException(
        'El archivo no es un respaldo compatible de Págame.',
      );
    }
    final contacts = (decoded['contacts'] as List<dynamic>? ?? const [])
        .map(
          (value) => Contact.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final debts = (decoded['debts'] as List<dynamic>? ?? const [])
        .map((value) => Debt.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    final payments = (decoded['payments'] as List<dynamic>? ?? const [])
        .map(
          (value) => Payment.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final installments = (decoded['installments'] as List<dynamic>? ?? const [])
        .map(
          (value) =>
              Installment.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final reminders = (decoded['reminders'] as List<dynamic>? ?? const [])
        .map(
          (value) => Reminder.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final debtAttachments = (decoded['debtAttachments'] as List<dynamic>? ??
            const [])
        .map(
          (value) =>
              DebtAttachment.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final paymentAttachments =
        (decoded['paymentAttachments'] as List<dynamic>? ?? const [])
            .map(
              (value) => PaymentAttachment.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
            )
            .toList();
    final groups = (decoded['groups'] as List<dynamic>? ?? const [])
        .map((value) => Group.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    final participants = (decoded['participants'] as List<dynamic>? ?? const [])
        .map(
          (value) => GroupParticipant.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    final settings = (decoded['settings'] as List<dynamic>? ?? const [])
        .map(
          (value) =>
              AppSetting.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final profileValue = decoded['profile'];
    final profile = profileValue == null
        ? null
        : AppProfile.fromJson(Map<String, dynamic>.from(profileValue as Map));
    await db.transaction(() async {
      await db.delete(db.paymentAttachments).go();
      await db.delete(db.debtAttachments).go();
      await db.delete(db.reminders).go();
      await db.delete(db.installments).go();
      await db.delete(db.payments).go();
      await db.delete(db.groupParticipants).go();
      await db.delete(db.groups).go();
      await db.delete(db.debts).go();
      await db.delete(db.contacts).go();
      await db.delete(db.appProfiles).go();
      await db.delete(db.appSettings).go();
      if (profile != null) await db.into(db.appProfiles).insert(profile);
      if (contacts.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.contacts, contacts));
      }
      if (debts.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.debts, debts));
      }
      if (payments.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.payments, payments));
      }
      if (installments.isNotEmpty) {
        await db
            .batch((batch) => batch.insertAll(db.installments, installments));
      }
      if (reminders.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.reminders, reminders));
      }
      if (debtAttachments.isNotEmpty) {
        await db.batch(
          (batch) => batch.insertAll(db.debtAttachments, debtAttachments),
        );
      }
      if (paymentAttachments.isNotEmpty) {
        await db.batch(
          (batch) => batch.insertAll(db.paymentAttachments, paymentAttachments),
        );
      }
      if (groups.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.groups, groups));
      }
      if (participants.isNotEmpty) {
        await db.batch(
          (batch) => batch.insertAll(db.groupParticipants, participants),
        );
      }
      if (settings.isNotEmpty) {
        await db.batch((batch) => batch.insertAll(db.appSettings, settings));
      }
      await _activity(
        'backup_restored',
        'backup',
        _uuid.v4(),
        'Respaldo restaurado correctamente',
      );
    });
  }

  Future<void> _activity(
    String type,
    String entityType,
    String entityId,
    String description,
  ) =>
      db.into(db.activityEvents).insert(
            ActivityEventsCompanion.insert(
              id: _uuid.v4(),
              eventType: type,
              entityType: entityType,
              entityId: entityId,
              description: description,
              createdAt: DateTime.now().toUtc(),
            ),
          );

  String _publicCode() =>
      'PG-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  String _resolveStatus(
    int outstanding,
    int paid,
    DateTime? dueDate,
    DateTime now,
  ) {
    if (outstanding == 0) return 'paid';
    if (dueDate != null && dueDate.isBefore(now)) return 'overdue';
    if (paid > 0) return 'partiallyPaid';
    return 'active';
  }

  static String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}
