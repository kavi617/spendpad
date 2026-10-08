import 'package:flutter_test/flutter_test.dart';
import 'package:spendpad/utils/app_format.dart';

void main() {
  test('Indian currency grouping', () {
    expect(AppFormat.money(816), '₹816.00');
    expect(AppFormat.money(1234.5), '₹1,234.50');
    expect(AppFormat.money(1234567), '₹12,34,567.00');
  });

  test('Compact money', () {
    expect(AppFormat.moneyCompact(92200), '₹92.2K');
    expect(AppFormat.moneyCompact(1234567), '₹12.3L');
    expect(AppFormat.moneyCompact(25000000), '₹2.5Cr');
    expect(AppFormat.moneyCompact(816), '₹816');
  });

  test('Relative day', () {
    final now = DateTime.now();
    expect(AppFormat.relativeDay(now), 'Today');
    expect(AppFormat.relativeDay(now.subtract(const Duration(days: 1))),
        'Yesterday');
  });

  test('ISO date', () {
    expect(AppFormat.isoDate(DateTime(2026, 9, 4)), '2026-09-04');
  });
}
