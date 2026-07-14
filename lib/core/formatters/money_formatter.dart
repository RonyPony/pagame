import '../../features/debts/domain/entities/money.dart';

class MoneyFormatter {
  const MoneyFormatter({this.locale = 'es_DO'});
  final String locale;
  String format(Money money) => money.format(locale: locale);
}
