import 'package:intl/intl.dart';

class Money implements Comparable<Money> {
  const Money({required this.amountInMinorUnits, required this.currencyCode})
      : assert(amountInMinorUnits >= 0),
        assert(currencyCode.length == 3);

  final int amountInMinorUnits;
  final String currencyCode;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(
      amountInMinorUnits: amountInMinorUnits + other.amountInMinorUnits,
      currencyCode: currencyCode,
    );
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    final result = amountInMinorUnits - other.amountInMinorUnits;
    if (result < 0) {
      throw ArgumentError('Money subtraction cannot produce a negative value.');
    }
    return Money(amountInMinorUnits: result, currencyCode: currencyCode);
  }

  bool get isZero => amountInMinorUnits == 0;

  String format({String locale = 'es_DO'}) {
    final value = amountInMinorUnits / 100;
    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
    );
    return formatter.format(value);
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amountInMinorUnits.compareTo(other.amountInMinorUnits);
  }

  void _assertSameCurrency(Money other) {
    if (currencyCode != other.currencyCode) {
      throw ArgumentError('Cannot operate with different currencies.');
    }
  }
}
