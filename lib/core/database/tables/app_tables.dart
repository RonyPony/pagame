import 'package:drift/drift.dart';

class AppProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get defaultCurrency => text().withDefault(const Constant('DOP'))();
  TextColumn get countryCode => text().withDefault(const Constant('DO'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().nullable()();
  TextColumn get alias => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get publicCode => text().unique()();
  TextColumn get direction => text()();
  TextColumn get contactId => text().nullable().references(Contacts, #id)();
  TextColumn get contactNameSnapshot => text()();
  TextColumn get contactPhoneSnapshot => text().nullable()();
  IntColumn get amountInMinorUnits => integer()();
  IntColumn get paidAmountInMinorUnits =>
      integer().withDefault(const Constant(0))();
  IntColumn get outstandingAmountInMinorUnits => integer()();
  TextColumn get currencyCode => text()();
  TextColumn get concept => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get loanDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get agreementStatus => text()();
  TextColumn get paymentType => text().withDefault(const Constant('single'))();
  IntColumn get installmentCount => integer().nullable()();
  TextColumn get installmentFrequency => text().nullable()();
  BoolColumn get allowPartialPayments =>
      boolean().withDefault(const Constant(true))();
  TextColumn get privateNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  IntColumn get amountInMinorUnits => integer()();
  TextColumn get currencyCode => text()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMethod => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Installments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  IntColumn get number => integer()();
  IntColumn get amountInMinorUnits => integer()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get paidAmountInMinorUnits =>
      integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  TextColumn get installmentId =>
      text().nullable().references(Installments, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get repeatRule => text().nullable()();
  TextColumn get status => text()();
  IntColumn get platformNotificationId => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class DebtAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  TextColumn get fileName => text()();
  TextColumn get storedPath => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class PaymentAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get paymentId => text().references(Payments, #id)();
  TextColumn get fileName => text()();
  TextColumn get storedPath => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get currencyCode => text()();
  IntColumn get totalAmountInMinorUnits => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get status => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class GroupParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get contactId => text().nullable().references(Contacts, #id)();
  TextColumn get contactNameSnapshot => text()();
  IntColumn get assignedAmountInMinorUnits => integer()();
  IntColumn get paidAmountInMinorUnits =>
      integer().withDefault(const Constant(0))();
  IntColumn get outstandingAmountInMinorUnits => integer()();
  TextColumn get status => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class ActivityEvents extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get description => text()();
  TextColumn get metadataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get localeKey => text()();
  TextColumn get iconName => text().nullable()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {key};
}
