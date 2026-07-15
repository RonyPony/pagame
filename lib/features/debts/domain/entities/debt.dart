import '../enums/debt_enums.dart';
import 'money.dart';

class Debt {
  const Debt({
    required this.id,
    required this.publicCode,
    required this.direction,
    required this.contactNameSnapshot,
    required this.amount,
    required this.paidAmount,
    required this.concept,
    required this.loanDate,
    required this.status,
    required this.agreementStatus,
    required this.allowPartialPayments,
    required this.createdAt,
    required this.updatedAt,
    this.contactId,
    this.contactPhoneSnapshot,
    this.description,
    this.categoryId,
    this.dueDate,
    this.privateNote,
    this.completedAt,
    this.cancelledAt,
    this.archivedAt,
  });

  final String id;
  final String publicCode;
  final DebtDirection direction;
  final String? contactId;
  final String contactNameSnapshot;
  final String? contactPhoneSnapshot;
  final Money amount;
  final Money paidAmount;
  final String concept;
  final String? description;
  final String? categoryId;
  final DateTime loanDate;
  final DateTime? dueDate;
  final DebtStatus status;
  final AgreementStatus agreementStatus;
  final bool allowPartialPayments;
  final String? privateNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? archivedAt;

  Money get outstandingAmount => amount - paidAmount;
}
