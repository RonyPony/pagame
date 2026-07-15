enum DebtDirection { receivable, payable }

enum DebtStatus {
  draft,
  active,
  partiallyPaid,
  paid,
  overdue,
  cancelled,
  disputed,
  archived
}

enum AgreementStatus {
  notSpecified,
  verbalAgreement,
  writtenAgreement,
  signedLocally,
  disputed
}

enum PaymentType { single, installments }

enum InstallmentFrequency { weekly, biweekly, monthly, custom }
