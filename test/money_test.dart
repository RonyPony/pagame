import 'package:flutter_test/flutter_test.dart';
import 'package:pagame/features/debts/domain/entities/money.dart';

void main() {
  test('suma y resta montos en la misma moneda', () {
    const a = Money(amountInMinorUnits: 250050, currencyCode: 'DOP');
    const b = Money(amountInMinorUnits: 5000, currencyCode: 'DOP');
    expect((a + b).amountInMinorUnits, 255050);
    expect((a - b).amountInMinorUnits, 245050);
  });

  test('rechaza operaciones entre monedas diferentes', () {
    const dop = Money(amountInMinorUnits: 100, currencyCode: 'DOP');
    const usd = Money(amountInMinorUnits: 100, currencyCode: 'USD');
    expect(() => dop + usd, throwsArgumentError);
  });
}
