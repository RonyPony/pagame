import '../entities/debt.dart';
import '../enums/debt_enums.dart';

class DebtStatusService {
  const DebtStatusService();

  DebtStatus resolve(Debt debt, DateTime now) {
    if (debt.status == DebtStatus.cancelled ||
        debt.status == DebtStatus.disputed ||
        debt.status == DebtStatus.archived ||
        debt.status == DebtStatus.draft) {
      return debt.status;
    }
    if (debt.outstandingAmount.isZero) {
      return DebtStatus.paid;
    }
    final dueDate = debt.dueDate;
    if (dueDate != null && _dateOnly(dueDate).isBefore(_dateOnly(now))) {
      return DebtStatus.overdue;
    }
    if (!debt.paidAmount.isZero) {
      return DebtStatus.partiallyPaid;
    }
    return DebtStatus.active;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
